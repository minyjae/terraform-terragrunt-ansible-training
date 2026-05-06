# Ansible - อธิบายการทำงาน

## ภาพรวม

Ansible ในโปรเจกต์นี้ทำหน้าที่ **provisioning** เซิร์ฟเวอร์ที่ Terraform/Terragrunt สร้างขึ้นมา
โดยจะติดตั้ง Docker Swarm cluster พร้อม Traefik (reverse proxy) และ Portainer (Docker UI)

```
Terraform สร้าง EC2 → Ansible เข้าไปติดตั้ง Docker + Swarm + Traefik + Portainer
```

---

## โครงสร้างไฟล์

```
ansible/
├── playbook.yml                          # ไฟล์หลัก กำหนดลำดับการรัน
├── inventory.ini.example                 # ตัวอย่าง inventory (ระบุ IP เซิร์ฟเวอร์)
└── roles/
    ├── docker/tasks/main.yml             # Step 1: ติดตั้ง Docker
    ├── swarm-manager/tasks/main.yml      # Step 2: สร้าง Swarm Manager
    ├── swarm-worker/tasks/main.yml       # Step 3: Worker join Swarm
    ├── traefik/
    │   ├── tasks/main.yml                # Step 4: Deploy Traefik
    │   └── templates/traefik-stack.yml.j2  # Template สำหรับ Traefik config
    └── portainer/tasks/main.yml          # Step 5: Deploy Portainer
```

---

## วิธีรัน

```bash
ansible-playbook -i inventory.ini playbook.yml
```

---

## Inventory (กำหนดเซิร์ฟเวอร์เป้าหมาย)

ไฟล์ `inventory.ini.example` กำหนดว่า Ansible จะ SSH ไปยังเซิร์ฟเวอร์ไหนบ้าง:

```ini
[manager]
1.2.3.4               # IP ของ Swarm Manager (1 เครื่อง)

[workers]
5.6.7.8               # IP ของ Worker 1
9.10.11.12            # IP ของ Worker 2

[swarm:children]       # กลุ่ม "swarm" = manager + workers รวมกัน
manager
workers

[all:vars]             # ตัวแปรใช้ร่วม
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/your-key.pem
```

- **manager** — 1 เครื่อง ทำหน้าที่เป็น Swarm Manager
- **workers** — หลายเครื่อง ทำหน้าที่เป็น Swarm Worker
- **swarm** — กลุ่มรวม ใช้ตอนติดตั้ง Docker บนทุกเครื่อง

---

## ลำดับการทำงาน (Playbook)

`playbook.yml` กำหนดลำดับการทำงาน 5 ขั้นตอน:

```
Step 1: ติดตั้ง Docker บนทุก node (manager + workers)
           │
Step 2: สร้าง Swarm Manager (init cluster)
           │
Step 3: Workers join เข้า Swarm cluster
           │
Step 4: Deploy Traefik (reverse proxy) บน Manager
           │
Step 5: Deploy Portainer (Docker UI) บน Manager
```

---

### Step 1: ติดตั้ง Docker (`roles/docker`)

**รันบน:** ทุก node (`hosts: swarm`)

ติดตั้ง Docker Engine บน Ubuntu ตามขั้นตอน official:

```yaml
# 1. อัปเดต apt cache
- name: Update apt cache
  apt:
    update_cache: true
    cache_valid_time: 3600          # cache 1 ชม. ไม่ต้อง update ซ้ำ

# 2. ติดตั้ง packages ที่จำเป็น (curl, gpg ฯลฯ)
- name: Install required packages
  apt:
    name:
      - apt-transport-https
      - ca-certificates
      - curl
      - gnupg
      - lsb-release

# 3. เพิ่ม GPG key ของ Docker
- name: Add Docker GPG key
  shell: |
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      -o /etc/apt/keyrings/docker.asc
  args:
    creates: /etc/apt/keyrings/docker.asc   # ถ้ามีแล้วจะข้าม (idempotent)

# 4. เพิ่ม Docker apt repository
- name: Add Docker repository
  shell: |
    echo "deb [arch=... signed-by=.../docker.asc] \
      https://download.docker.com/linux/ubuntu ... stable" \
      | tee /etc/apt/sources-list.d/docker.list
  args:
    creates: /etc/apt/sources-list.d/docker.list

# 5. ติดตั้ง Docker CE + CLI + containerd + compose plugin
- name: Install Docker
  apt:
    name:
      - docker-ce
      - docker-ce-cli
      - containerd.io
      - docker-compose-plugin

# 6. เปิด Docker service + ตั้งให้ start ตอนบูต
- name: Start and enable Docker
  systemd:
    name: docker
    state: started
    enabled: true

# 7. เพิ่ม user "ubuntu" เข้ากลุ่ม docker (ให้รัน docker ได้โดยไม่ต้อง sudo)
- name: Add ubuntu user to docker group
  user:
    name: ubuntu
    groups: docker
    append: true
```

---

### Step 2: สร้าง Swarm Manager (`roles/swarm-manager`)

**รันบน:** เฉพาะ manager (`hosts: manager`)

```yaml
# 1. เช็คว่า Swarm init แล้วหรือยัง
- name: Check if Swarm is already initialized
  command: docker info --format '{{ .Swarm.LocalNodeState }}'
  register: swarm_status          # เก็บผลลัพธ์ไว้ใน variable

# 2. ถ้ายังไม่ init → docker swarm init
- name: Initialize Docker Swarm
  command: >
    docker swarm init
    --advertise-addr {{ ansible_default_ipv4.address }}
  when: swarm_status.stdout != "active"    # รันเมื่อยังไม่ได้ init เท่านั้น

# 3. ดึง join token สำหรับ worker
- name: Get worker join token
  command: docker swarm join-token worker -q
  register: worker_token

# 4. บันทึก token + IP เป็น fact (ส่งต่อให้ Step 3 ใช้)
- name: Save worker token as fact
  set_fact:
    swarm_worker_token: "{{ worker_token.stdout }}"
    swarm_manager_ip: "{{ ansible_default_ipv4.address }}"

# 5. สร้าง overlay network สำหรับ Traefik
- name: Create overlay network for Traefik
  command: >
    docker network create --driver overlay --attachable traefik-public
  failed_when: rc != 0 and 'already exists' not in stderr
```

**จุดสำคัญ:** `set_fact` เก็บ token ไว้ → worker role จะดึงค่านี้ไปใช้ผ่าน `hostvars`

---

### Step 3: Worker join Swarm (`roles/swarm-worker`)

**รันบน:** ทุก worker (`hosts: workers`)

```yaml
# 1. เช็คว่า join Swarm แล้วหรือยัง
- name: Check if already in Swarm
  command: docker info --format '{{ .Swarm.LocalNodeState }}'
  register: swarm_status

# 2. ถ้ายังไม่ได้ join → ใช้ token จาก manager เพื่อ join
- name: Join Swarm as worker
  command: >
    docker swarm join
    --token {{ hostvars[groups['manager'][0]].swarm_worker_token }}
    {{ hostvars[groups['manager'][0]].swarm_manager_ip }}:2377
  when: swarm_status.stdout != "active"
```

**จุดสำคัญ:** `hostvars[groups['manager'][0]]` คือการดึงค่า `swarm_worker_token` และ `swarm_manager_ip` ที่ manager เก็บไว้ใน Step 2

---

### Step 4: Deploy Traefik (`roles/traefik`)

**รันบน:** เฉพาะ manager (`hosts: manager`)

Traefik คือ **reverse proxy** ที่ route traffic ไปยัง service ต่างๆ ใน Swarm

```yaml
# 1. สร้าง directory สำหรับเก็บ config
- name: Create Traefik directory
  file:
    path: /opt/traefik
    state: directory

# 2. Copy template ไปเป็นไฟล์จริงบนเซิร์ฟเวอร์
- name: Copy Traefik stack file
  template:
    src: traefik-stack.yml.j2       # Jinja2 template
    dest: /opt/traefik/traefik-stack.yml

# 3. Deploy ด้วย docker stack
- name: Deploy Traefik stack
  command: docker stack deploy -c /opt/traefik/traefik-stack.yml traefik

# 4. รอ 10 วินาที แล้วเช็คสถานะ
- name: Wait for Traefik to start
  pause:
    seconds: 10

- name: Verify Traefik is running
  command: docker service ls --filter name=traefik_traefik
```

#### Traefik Stack Template (`traefik-stack.yml.j2`)

```yaml
services:
  traefik:
    image: traefik:v3.0
    command:
      - "--api.dashboard=true"              # เปิด Dashboard
      - "--api.insecure=true"               # Dashboard ไม่ต้อง login (dev only)
      - "--providers.swarm.endpoint=unix:///var/run/docker.sock"
      - "--providers.swarm.exposedByDefault=false"   # ต้องติด label ถึง expose
      - "--providers.swarm.network=traefik-public"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"

    ports:
      - "80:80"         # HTTP
      - "443:443"       # HTTPS
      - "8080:8080"     # Dashboard

    deploy:
      placement:
        constraints:
          - node.role == manager   # Traefik รันบน manager เท่านั้น
```

**Ports ที่เปิด:**
| Port | ใช้ทำอะไร |
|------|----------|
| 80   | HTTP traffic |
| 443  | HTTPS traffic |
| 8080 | Traefik Dashboard |

---

### Step 5: Deploy Portainer (`roles/portainer`)

**รันบน:** เฉพาะ manager (`hosts: manager`)

Portainer คือ **Web UI** สำหรับจัดการ Docker containers, services, stacks

```yaml
# 1. สร้าง Docker volume เก็บ data ของ Portainer
- name: Create Portainer data volume
  command: docker volume create portainer_data

# 2. Deploy เป็น Swarm service
- name: Deploy Portainer as Swarm service
  command: >
    docker service create
    --name portainer
    --publish 9443:9443                          # HTTPS port
    --replicas=1
    --constraint 'node.role == manager'          # รันบน manager เท่านั้น
    --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock
    --mount type=volume,src=portainer_data,dst=/data
    portainer/portainer-ce:latest

# 3. รอ 15 วินาที แล้วเช็คสถานะ + แสดง URL
- name: Show Portainer status
  debug:
    msg: |
      Portainer replicas: {{ portainer_status.stdout }}
      Access Portainer at: https://<MANAGER_IP>:9443
```

---

## สรุป Flow ทั้งหมด

```
┌─────────────────────────────────────────────────────┐
│                    Ansible Playbook                  │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Step 1: [ทุก node]                                  │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐       │
│  │ Manager   │  │ Worker 1  │  │ Worker 2  │       │
│  │ Docker ✓  │  │ Docker ✓  │  │ Docker ✓  │       │
│  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘       │
│        │               │              │              │
│  Step 2: [manager only]│              │              │
│  ┌─────┴─────┐         │              │              │
│  │ swarm init│         │              │              │
│  │ get token │         │              │              │
│  └─────┬─────┘         │              │              │
│        │               │              │              │
│  Step 3:        [workers join]                       │
│        │         ┌─────┴─────┐  ┌─────┴─────┐       │
│        ├────────→│ join swarm│  │ join swarm│       │
│        │ token   └───────────┘  └───────────┘       │
│        │                                             │
│  Step 4: [manager only]                              │
│  ┌─────┴──────────┐                                 │
│  │ Deploy Traefik │  ← reverse proxy (:80, :443)    │
│  └─────┬──────────┘                                 │
│        │                                             │
│  Step 5: [manager only]                              │
│  ┌─────┴────────────┐                               │
│  │ Deploy Portainer │  ← Docker UI (:9443)          │
│  └──────────────────┘                               │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## ผลลัพธ์หลังรันสำเร็จ

| Service   | URL                          | หน้าที่                    |
|-----------|------------------------------|--------------------------|
| Traefik   | `http://<MANAGER_IP>:8080`   | Reverse proxy dashboard  |
| Portainer | `https://<MANAGER_IP>:9443`  | Docker management UI     |
| App HTTP  | `http://<MANAGER_IP>`        | Application traffic      |
| App HTTPS | `https://<MANAGER_IP>`       | Application traffic (SSL)|
