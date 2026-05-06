# Jenkins vs Ansible - เปรียบเทียบและการใช้งาน

## สารบัญ

1. [Jenkins คืออะไร?](#1-jenkins-คืออะไร)
2. [Ansible คืออะไร? (ทบทวน)](#2-ansible-คืออะไร-ทบทวน)
3. [เปรียบเทียบ Jenkins vs Ansible](#3-เปรียบเทียบ-jenkins-vs-ansible)
4. [สิ่งที่เหมือนกัน](#4-สิ่งที่เหมือนกัน)
5. [สิ่งที่แตกต่างกัน](#5-สิ่งที่แตกต่างกัน)
6. [ส่วนประกอบของ Jenkins Project](#6-ส่วนประกอบของ-jenkins-project)
7. [Step-by-Step: ทำงานเหมือน Ansible ด้วย Jenkins](#7-step-by-step-ทำงานเหมือน-ansible-ด้วย-jenkins)
8. [ตัวอย่าง Jenkinsfile สำหรับโปรเจคนี้](#8-ตัวอย่าง-jenkinsfile-สำหรับโปรเจคนี้)
9. [เมื่อไหร่ควรใช้อะไร](#9-เมื่อไหร่ควรใช้อะไร)
10. [Best Practice: ใช้ร่วมกัน](#10-best-practice-ใช้ร่วมกัน)

---

## 1. Jenkins คืออะไร?

Jenkins เป็น **CI/CD Automation Server** แบบ open-source ที่ใช้สำหรับ:
- **Continuous Integration (CI):** Build, Test โค้ดอัตโนมัติทุกครั้งที่ push
- **Continuous Delivery/Deployment (CD):** Deploy แอปพลิเคชันไปยัง server อัตโนมัติ
- **Pipeline Orchestration:** จัดลำดับขั้นตอนการทำงานทั้งหมดแบบ end-to-end

### สถาปัตยกรรมของ Jenkins

```
┌─────────────────────────────────────────────────────┐
│                  Jenkins Controller                  │
│  (Master Server - จัดการ Pipeline, UI, Scheduling)   │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │ Agent 1  │  │ Agent 2  │  │ Agent 3  │          │
│  │ (Build)  │  │ (Test)   │  │ (Deploy) │          │
│  └──────────┘  └──────────┘  └──────────┘          │
│                                                     │
│  Pipeline: Build → Test → Deploy                    │
│  Plugins: Git, Docker, AWS, Terraform, Ansible      │
└─────────────────────────────────────────────────────┘
```

### คำศัพท์สำคัญของ Jenkins

| คำศัพท์ | ความหมาย |
|---------|----------|
| **Controller (Master)** | เซิร์ฟเวอร์หลักที่รัน Jenkins, จัดการ UI และ scheduling |
| **Agent (Node/Slave)** | เครื่องที่รัน job จริงๆ (build, test, deploy) |
| **Pipeline** | ชุดขั้นตอนทั้งหมดจาก code → production |
| **Stage** | กลุ่มของ step ที่ทำงานร่วมกัน (เช่น Build, Test, Deploy) |
| **Step** | คำสั่งเดี่ยวใน stage (เช่น `sh 'npm install'`) |
| **Jenkinsfile** | ไฟล์ที่เขียน Pipeline as Code (เหมือน playbook ของ Ansible) |
| **Plugin** | ส่วนเสริมที่เพิ่มความสามารถให้ Jenkins |
| **Workspace** | โฟลเดอร์ทำงานของ job บน agent |
| **Trigger** | สิ่งที่กระตุ้นให้ pipeline ทำงาน (webhook, cron, manual) |

---

## 2. Ansible คืออะไร? (ทบทวน)

Ansible เป็น **Configuration Management & Automation Tool** ที่ใช้สำหรับ:
- **Configuration Management:** ตั้งค่า server ให้เป็นสถานะที่ต้องการ
- **Application Deployment:** deploy แอปไปยัง server
- **Orchestration:** จัดลำดับการทำงานข้ามหลาย server

### สถาปัตยกรรมของ Ansible (จากโปรเจคนี้)

```
┌─────────────────────────────────────────────────────┐
│              Control Node (เครื่องเรา)               │
│  ansible-playbook -i inventory playbook.yml         │
├─────────────────────────────────────────────────────┤
│                    SSH                               │
│  ┌──────────────┐  ┌─────────────┐  ┌─────────────┐│
│  │ Manager Node │  │ Worker 01   │  │ Worker 02   ││
│  │ 52.77.251.92 │  │47.129.222..│  │  (IP)       ││
│  └──────────────┘  └─────────────┘  └─────────────┘│
│                                                     │
│  Roles: docker → swarm-manager → swarm-worker       │
│       → traefik → portainer → webapp                │
└─────────────────────────────────────────────────────┘
```

---

## 3. เปรียบเทียบ Jenkins vs Ansible

### ตารางเปรียบเทียบ

| หัวข้อ | Jenkins | Ansible |
|--------|---------|---------|
| **ประเภท** | CI/CD Automation Server | Configuration Management Tool |
| **จุดประสงค์หลัก** | Build, Test, Deploy Pipeline | ตั้งค่า & จัดการ Server |
| **การเขียน** | Jenkinsfile (Groovy DSL) | Playbook (YAML) |
| **การเชื่อมต่อ Server** | Agent-based (ต้องติดตั้ง agent) | Agentless (ใช้ SSH) |
| **State Management** | ไม่มี (procedural) | Idempotent (declarative) |
| **UI** | มี Web UI ในตัว | ไม่มี UI (CLI-based, ยกเว้น AWX/Tower) |
| **Trigger** | Webhook, Cron, Manual, Event | Manual หรือ cron (ต้องใช้ tool อื่นช่วย) |
| **Plugin System** | มีมากกว่า 1,800 plugins | มี Collections/Modules |
| **ภาษาที่ใช้เขียน** | Java | Python |
| **Learning Curve** | ปานกลาง-สูง | ต่ำ-ปานกลาง |
| **Infrastructure** | ต้องมี server รัน Jenkins | ไม่ต้องมี server (รันจากเครื่อง local ได้) |

---

## 4. สิ่งที่เหมือนกัน

### 4.1 Automation (ทำงานอัตโนมัติ)

ทั้งคู่ทำงาน **อัตโนมัติ** ตามขั้นตอนที่กำหนด

```
Ansible:  playbook.yml  → ทำตาม roles ทีละ step
Jenkins:  Jenkinsfile   → ทำตาม stages ทีละ step
```

### 4.2 Pipeline / Workflow as Code

ทั้งคู่เขียนขั้นตอนเป็น **ไฟล์ code** ที่ version control ด้วย Git ได้

**Ansible Playbook:**
```yaml
# playbook.yml
- name: Install Docker
  hosts: swarm
  roles:
    - docker

- name: Init Swarm Manager
  hosts: manager
  roles:
    - swarm-manager
```

**Jenkins Pipeline:**
```groovy
// Jenkinsfile
pipeline {
    stages {
        stage('Install Docker') {
            steps {
                sh 'ansible-playbook -i inventory playbook.yml --tags docker'
            }
        }
        stage('Init Swarm') {
            steps {
                sh 'ansible-playbook -i inventory playbook.yml --tags swarm'
            }
        }
    }
}
```

### 4.3 Multi-Step Execution (ทำงานหลายขั้นตอน)

ทั้งคู่รันขั้นตอนตามลำดับ:

```
Ansible:  Docker → Swarm Init → Workers Join → Traefik → Portainer → WebApp
Jenkins:  Build  → Test       → Stage        → Deploy  → Verify    → Notify
```

### 4.4 Parameterization (รับค่า parameter)

**Ansible:**
```yaml
# inventory.yml
all:
  vars:
    project_name: web-app-develop
    env_name: develop
    aws_region: ap-southeast-1
```

**Jenkins:**
```groovy
pipeline {
    parameters {
        string(name: 'ENVIRONMENT', defaultValue: 'develop')
        string(name: 'AWS_REGION', defaultValue: 'ap-southeast-1')
    }
}
```

### 4.5 Reusability (ใช้ซ้ำได้)

**Ansible:** ใช้ **Roles** แยกเป็น module (docker/, swarm-manager/, traefik/, ...)
**Jenkins:** ใช้ **Shared Libraries** แยกเป็น function ที่ใช้ซ้ำข้าม pipeline

---

## 5. สิ่งที่แตกต่างกัน

### 5.1 จุดประสงค์หลัก (Core Purpose)

```
┌────────────────────────────────────────────────────┐
│                CI/CD Pipeline                       │
│                                                    │
│  Code → Build → Test → Package → Deploy → Monitor  │
│  ▲                                                 │
│  │ Jenkins เก่งตรงนี้ทั้งหมด                        │
│  │ (Orchestrate ทุกขั้นตอน)                         │
│                                                    │
│  Ansible เก่งเฉพาะ                                  │
│  Deploy + Configure ──────────┐                    │
│                               ▼                    │
│                    ┌──────────────────┐             │
│                    │ Server Config    │             │
│                    │ Install packages │             │
│                    │ Deploy services  │             │
│                    │ Manage state     │             │
│                    └──────────────────┘             │
└────────────────────────────────────────────────────┘
```

**สรุป:**
- **Jenkins** = Orchestrator (ผู้จัดการทั้ง pipeline)
- **Ansible** = Executor (ผู้ลงมือทำบน server)

### 5.2 Agent vs Agentless

```
Jenkins (Agent-based):
┌──────────┐     install agent     ┌──────────┐
│ Jenkins  │ ──────────────────→   │ Target   │
│ Master   │     JNLP / SSH       │ Server   │
└──────────┘                       └──────────┘
  ต้องติดตั้ง Jenkins Agent บน target server

Ansible (Agentless):
┌──────────┐        SSH            ┌──────────┐
│ Control  │ ──────────────────→   │ Target   │
│ Node     │   ไม่ต้องติดตั้งอะไร   │ Server   │
└──────────┘                       └──────────┘
  แค่มี SSH + Python บน target ก็พอ
```

### 5.3 Idempotency (ความสามารถรันซ้ำได้)

**Ansible - Idempotent (รันกี่ครั้งก็ผลเหมือนกัน):**
```yaml
# รัน 100 ครั้งก็ได้ผลเหมือนกัน
- name: Ensure Docker is installed
  apt:
    name: docker-ce
    state: present    # ← ถ้ามีอยู่แล้วจะข้าม ไม่ install ซ้ำ

- name: Ensure Docker is running
  service:
    name: docker
    state: started    # ← ถ้า running อยู่แล้วจะไม่ restart
```

**Jenkins - Procedural (รันทุกครั้ง):**
```groovy
// รันทุกครั้งไม่ว่าจะ install แล้วหรือยัง
stage('Install Docker') {
    steps {
        sh 'apt-get install -y docker-ce'  // ← รันคำสั่งทุกครั้ง
    }
}
```

> **ข้อแตกต่างสำคัญ:** Ansible บอกว่า "ต้องการให้เป็นอย่างไร" (Declarative)
> Jenkins บอกว่า "ให้ทำอะไร" (Imperative/Procedural)

### 5.4 Error Handling

**Ansible:**
```yaml
- name: Deploy Traefik
  docker_stack:
    name: traefik
    compose: traefik-stack.yml
  register: result
  retries: 3           # ← ลองใหม่ 3 ครั้ง
  delay: 10            # ← รอ 10 วินาทีระหว่างครั้ง
  until: result is success

- name: Verify Traefik
  uri:
    url: "http://localhost:8080"
    status_code: 200
  ignore_errors: yes    # ← ถ้า fail ไม่หยุดทั้ง playbook
```

**Jenkins:**
```groovy
stage('Deploy Traefik') {
    steps {
        retry(3) {                    // ← ลองใหม่ 3 ครั้ง
            sh 'docker stack deploy traefik'
        }
    }
    post {
        failure {                      // ← ถ้า fail ส่ง notification
            slackSend message: "Deploy failed!"
        }
        success {
            slackSend message: "Deploy succeeded!"
        }
    }
}
```

### 5.5 Trigger & Scheduling

**Ansible:** ต้องรันเอง manual หรือใช้ cron / tool อื่น trigger
```bash
# Manual
ansible-playbook playbook.yml

# Cron (ใน crontab)
0 2 * * * ansible-playbook playbook.yml
```

**Jenkins:** มี trigger system ในตัว
```groovy
pipeline {
    triggers {
        // รันอัตโนมัติเมื่อ push code
        githubPush()

        // รันตาม schedule
        cron('H 2 * * *')

        // รันเมื่อ upstream job เสร็จ
        upstream('build-job')

        // Webhook จาก external system
        genericTrigger(token: 'deploy-token')
    }
}
```

### 5.6 UI & Visibility

```
Jenkins:
┌─────────────────────────────────────────────┐
│  Jenkins Dashboard                          │
│  ├── Pipeline View (Blue Ocean)             │
│  │   └── Build → Test → Deploy (visual)     │
│  ├── Build History (#1, #2, #3...)          │
│  ├── Console Output (real-time logs)        │
│  ├── Test Reports (JUnit, coverage)         │
│  ├── Artifacts (build outputs)              │
│  └── User Management (RBAC)                 │
└─────────────────────────────────────────────┘

Ansible:
┌─────────────────────────────────────────────┐
│  Terminal Output (CLI only)                 │
│                                             │
│  PLAY [Install Docker] **************       │
│  TASK [Install packages] ************       │
│  ok: [manager-01]                           │
│  changed: [worker-01]                       │
│  PLAY RECAP ****************************    │
│  manager-01 : ok=5  changed=2  failed=0     │
│  worker-01  : ok=5  changed=3  failed=0     │
│                                             │
│  (ต้องใช้ AWX/Tower ถ้าต้องการ Web UI)        │
└─────────────────────────────────────────────┘
```

---

## 6. ส่วนประกอบของ Jenkins Project

### 6.1 โครงสร้างไฟล์

```
project/
├── Jenkinsfile                    # Pipeline หลัก (เหมือน playbook.yml)
├── jenkins/
│   ├── Jenkinsfile.build          # Pipeline สำหรับ build
│   ├── Jenkinsfile.deploy         # Pipeline สำหรับ deploy
│   ├── scripts/                   # Shell scripts ที่ Jenkins เรียก
│   │   ├── install-docker.sh
│   │   ├── init-swarm.sh
│   │   ├── deploy-traefik.sh
│   │   └── deploy-app.sh
│   └── config/                    # Configuration files
│       ├── traefik-stack.yml
│       └── docker-compose.yml
├── vars/                          # Shared Library (ถ้าใช้)
│   └── deployPipeline.groovy
├── src/                           # Application source code
├── tests/                         # Test files
├── Dockerfile                     # Container build
└── docker-compose.yml             # Local development
```

### 6.2 เปรียบเทียบส่วนประกอบ

| Ansible Component | Jenkins Equivalent | หน้าที่ |
|---|---|---|
| `playbook.yml` | `Jenkinsfile` | ไฟล์หลักที่กำหนด workflow |
| `roles/` | `Shared Libraries` หรือ `scripts/` | โค้ดที่ใช้ซ้ำได้ |
| `inventory.yml` | `Environment Variables` / `Credentials` | กำหนด target & ค่าตัวแปร |
| `ansible.cfg` | Jenkins System Config (UI) | ตั้งค่า global |
| `group_vars/` | `Pipeline Parameters` | ค่าตัวแปรตาม environment |
| `templates/` (Jinja2) | `scripts/` + `envsubst` | Template ไฟล์ config |
| `handlers/` | `post { }` blocks | จัดการ event หลังทำงาน |
| `tasks/main.yml` | `stages { stage { steps { } } }` | ขั้นตอนการทำงาน |

---

## 7. Step-by-Step: ทำงานเหมือน Ansible ด้วย Jenkins

### เป้าหมาย: Deploy Docker Swarm + Traefik + Portainer (เหมือนที่ Ansible ทำในโปรเจคนี้)

### Step 1: ติดตั้ง Jenkins

```bash
# Option A: Docker (แนะนำ)
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts

# Option B: Ubuntu
sudo apt update
sudo apt install -y openjdk-17-jre
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list
sudo apt update
sudo apt install -y jenkins
sudo systemctl start jenkins
```

เข้าถึง Jenkins UI: `http://localhost:8080`

### Step 2: ติดตั้ง Plugins ที่จำเป็น

ไปที่ **Manage Jenkins → Plugins → Available plugins** ติดตั้ง:

| Plugin | ใช้ทำอะไร |
|--------|----------|
| **Pipeline** | เขียน Pipeline as Code (Jenkinsfile) |
| **Git** | ดึง source code จาก Git |
| **SSH Agent** | ใช้ SSH key เชื่อมต่อ server (เหมือน Ansible ใช้ SSH) |
| **Credentials Binding** | จัดการ secrets (passwords, API keys) |
| **Docker Pipeline** | Build & push Docker images |
| **AWS Steps** | ใช้งาน AWS CLI/SDK |
| **Terraform** | รัน Terraform commands |
| **Ansible** (optional) | เรียก Ansible จาก Jenkins |
| **Slack Notification** | ส่ง notification |

### Step 3: ตั้งค่า Credentials

ไปที่ **Manage Jenkins → Credentials → Global**

เพิ่ม credentials เหล่านี้:

```
1. SSH Private Key
   - ID: ec2-ssh-key
   - Type: SSH Username with private key
   - Username: ubuntu
   - Private Key: (paste content ของ training-devops-keypair.pem)

2. AWS Credentials
   - ID: aws-credentials
   - Type: AWS Credentials
   - Access Key ID: (your AWS access key)
   - Secret Access Key: (your AWS secret key)

3. Docker Registry (ECR)
   - ID: ecr-credentials
   - Type: Username with password
   - (หรือใช้ AWS credentials + aws ecr get-login-password)
```

### Step 4: สร้าง Jenkinsfile

```groovy
// Jenkinsfile
pipeline {
    agent any

    // ─── Parameters (เหมือน inventory vars ของ Ansible) ───
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['develop', 'staging', 'production'],
            description: 'Target environment'
        )
        string(
            name: 'MANAGER_IP',
            defaultValue: '52.77.251.92',
            description: 'Swarm Manager IP'
        )
        string(
            name: 'WORKER_IPS',
            defaultValue: '47.129.222.116',
            description: 'Comma-separated Worker IPs'
        )
        string(
            name: 'AWS_REGION',
            defaultValue: 'ap-southeast-1',
            description: 'AWS Region'
        )
    }

    // ─── Environment Variables ───
    environment {
        SSH_KEY = credentials('ec2-ssh-key')
        AWS_CREDS = credentials('aws-credentials')
        SSH_USER = 'ubuntu'
        SSH_OPTS = '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
    }

    // ─── Stages (เหมือน plays ใน playbook.yml) ───
    stages {

        // ═══ Stage 1: Install Docker (เหมือน role: docker) ═══
        stage('Install Docker on All Nodes') {
            steps {
                script {
                    def allIPs = [params.MANAGER_IP] + params.WORKER_IPS.split(',')
                    for (ip in allIPs) {
                        sshagent(['ec2-ssh-key']) {
                            sh """
                                ssh ${SSH_OPTS} ${SSH_USER}@${ip.trim()} '
                                    # Update apt cache
                                    sudo apt-get update

                                    # Install prerequisites
                                    sudo apt-get install -y \\
                                        curl gnupg ca-certificates apt-transport-https

                                    # Add Docker GPG key
                                    sudo install -m 0755 -d /etc/apt/keyrings
                                    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \\
                                        | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
                                    sudo chmod a+r /etc/apt/keyrings/docker.asc

                                    # Add Docker repository
                                    echo "deb [arch=\$(dpkg --print-architecture) \\
                                        signed-by=/etc/apt/keyrings/docker.asc] \\
                                        https://download.docker.com/linux/ubuntu \\
                                        \$(. /etc/os-release && echo \$VERSION_CODENAME) stable" \\
                                        | sudo tee /etc/apt/sources.list.d/docker.list

                                    # Install Docker
                                    sudo apt-get update
                                    sudo apt-get install -y \\
                                        docker-ce docker-ce-cli containerd.io \\
                                        docker-buildx-plugin docker-compose-plugin

                                    # Start Docker & add user
                                    sudo systemctl start docker
                                    sudo systemctl enable docker
                                    sudo usermod -aG docker ubuntu
                                '
                            """
                        }
                    }
                }
            }
        }

        // ═══ Stage 2: Init Swarm Manager (เหมือน role: swarm-manager) ═══
        stage('Initialize Docker Swarm') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    script {
                        // Check if swarm already initialized
                        def swarmStatus = sh(
                            script: "ssh ${SSH_OPTS} ${SSH_USER}@${params.MANAGER_IP} 'docker info --format \"{{.Swarm.LocalNodeState}}\"'",
                            returnStdout: true
                        ).trim()

                        if (swarmStatus != 'active') {
                            // Init swarm
                            sh """
                                ssh ${SSH_OPTS} ${SSH_USER}@${params.MANAGER_IP} '
                                    docker swarm init --advertise-addr ${params.MANAGER_IP}
                                '
                            """
                        }

                        // Get worker join token (เหมือน set_fact ใน Ansible)
                        env.SWARM_TOKEN = sh(
                            script: "ssh ${SSH_OPTS} ${SSH_USER}@${params.MANAGER_IP} 'docker swarm join-token -q worker'",
                            returnStdout: true
                        ).trim()

                        // Create overlay network
                        sh """
                            ssh ${SSH_OPTS} ${SSH_USER}@${params.MANAGER_IP} '
                                docker network ls | grep traefik-public || \\
                                docker network create --driver overlay --attachable traefik-public
                            '
                        """
                    }
                }
            }
        }

        // ═══ Stage 3: Join Workers (เหมือน role: swarm-worker) ═══
        stage('Join Workers to Swarm') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    script {
                        def workerIPs = params.WORKER_IPS.split(',')
                        for (ip in workerIPs) {
                            // Check if already in swarm
                            def nodeStatus = sh(
                                script: "ssh ${SSH_OPTS} ${SSH_USER}@${ip.trim()} 'docker info --format \"{{.Swarm.LocalNodeState}}\"'",
                                returnStdout: true
                            ).trim()

                            if (nodeStatus != 'active') {
                                sh """
                                    ssh ${SSH_OPTS} ${SSH_USER}@${ip.trim()} '
                                        docker swarm join \\
                                            --token ${env.SWARM_TOKEN} \\
                                            ${params.MANAGER_IP}:2377
                                    '
                                """
                            }
                        }
                    }
                }
            }
        }

        // ═══ Stage 4: Deploy Traefik (เหมือน role: traefik) ═══
        stage('Deploy Traefik') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh """
                        ssh ${SSH_OPTS} ${SSH_USER}@${params.MANAGER_IP} '
                            mkdir -p /opt/traefik

                            cat > /opt/traefik/traefik-stack.yml << "STACKEOF"
version: "3.8"
services:
  traefik:
    image: traefik:v3.0
    command:
      - "--api.dashboard=true"
      - "--api.insecure=true"
      - "--providers.swarm.endpoint=unix:///var/run/docker.sock"
      - "--providers.swarm.exposedByDefault=false"
      - "--providers.swarm.network=traefik-public"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--log.level=INFO"
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - traefik-public
    deploy:
      placement:
        constraints:
          - node.role == manager
      restart_policy:
        condition: on-failure

networks:
  traefik-public:
    external: true
STACKEOF

                            docker stack deploy -c /opt/traefik/traefik-stack.yml traefik
                        '
                    """
                    // Wait for Traefik to start
                    sleep(time: 10, unit: 'SECONDS')
                }
            }
        }

        // ═══ Stage 5: Deploy Portainer (เหมือน role: portainer) ═══
        stage('Deploy Portainer') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh """
                        ssh ${SSH_OPTS} ${SSH_USER}@${params.MANAGER_IP} '
                            # Create volume
                            docker volume ls | grep portainer_data || \\
                                docker volume create portainer_data

                            # Deploy Portainer
                            docker service ls | grep portainer || \\
                                docker service create \\
                                    --name portainer \\
                                    --publish 9443:9443 \\
                                    --constraint "node.role==manager" \\
                                    --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \\
                                    --mount type=volume,src=portainer_data,dst=/data \\
                                    portainer/portainer-ce:latest
                        '
                    """
                    // Wait for Portainer to start
                    sleep(time: 15, unit: 'SECONDS')
                }
            }
        }

        // ═══ Stage 6: Deploy Web App (เหมือน role: webapp) ═══
        stage('Deploy Web Application') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    withAWS(credentials: 'aws-credentials', region: params.AWS_REGION) {
                        sh """
                            ssh ${SSH_OPTS} ${SSH_USER}@${params.MANAGER_IP} '
                                # Login to ECR
                                aws ecr get-login-password --region ${params.AWS_REGION} \\
                                    | docker login --username AWS --password-stdin \\
                                    \$(aws sts get-caller-identity --query Account --output text).dkr.ecr.${params.AWS_REGION}.amazonaws.com

                                # Deploy app service
                                docker service ls | grep web-app || \\
                                    docker service create \\
                                        --name web-app \\
                                        --replicas 2 \\
                                        --constraint "node.role!=manager" \\
                                        --publish 80:3000 \\
                                        --network traefik-public \\
                                        \${ECR_IMAGE_URL}:latest
                            '
                        """
                    }
                }
            }
        }

        // ═══ Stage 7: Verify Deployment (Jenkins เพิ่มเติมจาก Ansible) ═══
        stage('Verify Deployment') {
            steps {
                script {
                    // Health check - Traefik Dashboard
                    sh "curl -s -o /dev/null -w '%{http_code}' http://${params.MANAGER_IP}:8080 | grep 200"

                    // Health check - Portainer
                    sh "curl -sk -o /dev/null -w '%{http_code}' https://${params.MANAGER_IP}:9443 | grep 200"

                    echo """
                    ╔═══════════════════════════════════════════╗
                    ║       Deployment Successful!              ║
                    ╠═══════════════════════════════════════════╣
                    ║ Traefik:   http://${params.MANAGER_IP}:8080   ║
                    ║ Portainer: https://${params.MANAGER_IP}:9443  ║
                    ╚═══════════════════════════════════════════╝
                    """
                }
            }
        }
    }

    // ─── Post Actions (เหมือน handlers ของ Ansible) ───
    post {
        success {
            echo 'Pipeline completed successfully!'
            // slackSend(message: "Deploy to ${params.ENVIRONMENT} succeeded!")
        }
        failure {
            echo 'Pipeline failed!'
            // slackSend(message: "Deploy to ${params.ENVIRONMENT} FAILED!", color: 'danger')
        }
        always {
            cleanWs()  // Clean workspace
        }
    }
}
```

### Step 5: สร้าง Jenkins Pipeline Job

1. ไปที่ Jenkins Dashboard → **New Item**
2. ตั้งชื่อ: `deploy-docker-swarm`
3. เลือก **Pipeline**
4. ใน Pipeline section:
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: `https://github.com/your-repo.git`
   - Script Path: `Jenkinsfile`
5. Save & **Build with Parameters**

### Step 6: รัน Pipeline

```
Jenkins UI → deploy-docker-swarm → Build with Parameters

   ENVIRONMENT: develop
   MANAGER_IP:  52.77.251.92
   WORKER_IPS:  47.129.222.116
   AWS_REGION:  ap-southeast-1

   → Build
```

---

## 8. ตัวอย่าง Jenkinsfile สำหรับโปรเจคนี้ (Full Pipeline: Terraform + Ansible)

### Option A: Jenkins เรียก Ansible (Best Practice)

```groovy
// Jenkinsfile - ใช้ Jenkins orchestrate + Ansible execute
pipeline {
    agent any

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['develop', 'staging', 'production'])
        choice(name: 'ACTION', choices: ['apply', 'plan', 'destroy'])
    }

    environment {
        AWS_CREDS = credentials('aws-credentials')
        TF_DIR = "terraform_and_terragrunt_and_ansible"
    }

    stages {
        // ── Terraform/Terragrunt: สร้าง Infrastructure ──
        stage('Terragrunt Plan') {
            steps {
                dir("${TF_DIR}/${params.ENVIRONMENT}/web-app") {
                    sh 'terragrunt init --terragrunt-non-interactive'
                    sh 'terragrunt plan'
                }
            }
        }

        stage('Terragrunt Apply') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                dir("${TF_DIR}/${params.ENVIRONMENT}/web-app") {
                    sh 'terragrunt apply -auto-approve'
                }
            }
        }

        // ── Ansible: ตั้งค่า Server ──
        stage('Run Ansible Playbook') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                dir("${TF_DIR}") {
                    sshagent(['ec2-ssh-key']) {
                        sh """
                            ansible-playbook \\
                                -i ansible/inventories/${params.ENVIRONMENT}/inventory.yml \\
                                ansible/playbook.yml
                        """
                    }
                }
            }
        }

        // ── Verify ──
        stage('Smoke Test') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                script {
                    def managerIP = sh(
                        script: "cd ${TF_DIR}/${params.ENVIRONMENT}/web-app && terragrunt output -raw manager_public_ip",
                        returnStdout: true
                    ).trim()

                    sh "curl -sf http://${managerIP}:8080 > /dev/null"
                    echo "Traefik is running at http://${managerIP}:8080"
                }
            }
        }
    }

    post {
        success { echo "Pipeline completed for ${params.ENVIRONMENT}" }
        failure { echo "Pipeline FAILED for ${params.ENVIRONMENT}" }
    }
}
```

### Option B: Jenkins ทำทุกอย่างเอง (ไม่ใช้ Ansible)

ดูได้จาก Jenkinsfile ใน [Step 4](#step-4-สร้าง-jenkinsfile) ด้านบน

---

## 9. เมื่อไหร่ควรใช้อะไร

### ใช้ Jenkins เมื่อ:

- ต้องการ **CI/CD Pipeline** ครบวงจร (Build → Test → Deploy)
- ต้องการ **trigger อัตโนมัติ** เมื่อ push code
- ต้องการ **Web UI** สำหรับ monitoring & history
- ต้องการ **approval workflow** (manual approval ก่อน deploy production)
- ทีมต้องการ **visibility** เห็นสถานะการ deploy ทุกคน

### ใช้ Ansible เมื่อ:

- ต้องการ **ตั้งค่า server** (install packages, config files)
- ต้องการ **idempotent** operations (รันซ้ำได้ปลอดภัย)
- ต้องการ **configuration drift detection** (ตรวจสอบว่า server ยังเป็นตามที่ตั้งค่าไว้)
- ต้องการ **agentless** (ไม่ต้องติดตั้งอะไรบน target)
- ต้องการจัดการ **หลาย server พร้อมกัน** อย่างง่ายดาย

### ใช้ทั้งคู่ร่วมกัน (แนะนำ):

```
Git Push → Jenkins Pipeline:
    ├── Stage: Terraform Apply (สร้าง infrastructure)
    ├── Stage: Ansible Playbook (ตั้งค่า server)
    ├── Stage: Build & Push Docker Image (CI)
    ├── Stage: Deploy to Swarm (CD)
    └── Stage: Health Check & Notify
```

---

## 10. Best Practice: ใช้ร่วมกัน

### Architecture ที่แนะนำ

```
┌──────────────────────────────────────────────────────────────┐
│                        Git Repository                        │
│  ├── Jenkinsfile              (Pipeline definition)          │
│  ├── terraform/               (Infrastructure code)          │
│  ├── ansible/                 (Configuration code)           │
│  ├── src/                     (Application code)             │
│  ├── Dockerfile               (Container build)              │
│  └── tests/                   (Tests)                        │
└──────────────────┬───────────────────────────────────────────┘
                   │ webhook trigger
                   ▼
┌──────────────────────────────────────────────────────────────┐
│                     Jenkins Pipeline                         │
│                                                              │
│  ┌─────────┐   ┌─────────┐   ┌──────────┐   ┌───────────┐  │
│  │  Build  │ → │  Test   │ → │ Terraform│ → │  Ansible  │  │
│  │  & Lint │   │  & Scan │   │  Apply   │   │  Playbook │  │
│  └─────────┘   └─────────┘   └──────────┘   └───────────┘  │
│                                     │              │         │
│                                     ▼              ▼         │
│  ┌──────────┐                ┌────────────────────────┐     │
│  │  Notify  │ ←──────────── │   AWS Infrastructure   │     │
│  │  Slack   │                │   EC2 + Docker Swarm   │     │
│  └──────────┘                └────────────────────────┘     │
└──────────────────────────────────────────────────────────────┘
```

### บทบาทของแต่ละ tool

| Layer | Tool | หน้าที่ |
|-------|------|---------|
| **Orchestration** | Jenkins | จัดการ pipeline, trigger, approve, notify |
| **Infrastructure** | Terraform + Terragrunt | สร้าง AWS resources (EC2, RDS, S3, ECR) |
| **Configuration** | Ansible | ตั้งค่า server (Docker, Swarm, Traefik, Portainer) |
| **Containerization** | Docker | Package application เป็น container |
| **Routing** | Traefik | Reverse proxy & load balancing |
| **Management** | Portainer | Docker management UI |

### สรุปง่ายๆ

```
Jenkins    = "ผู้จัดการ" → สั่งว่า "เมื่อไหร่" ทำอะไร & ใครทำ
Terraform  = "ผู้สร้าง"  → สร้างโครงสร้างพื้นฐาน (server, database, network)
Ansible    = "ผู้ตั้งค่า" → ตั้งค่าสิ่งที่ Terraform สร้างมา (install, config, deploy)
Docker     = "ผู้บรรจุ"  → package app เป็น container พร้อม deploy
```

---

## Appendix: Quick Reference

### Ansible Command → Jenkins Equivalent

```bash
# Ansible: รัน playbook
ansible-playbook -i inventory playbook.yml

# Jenkins: ใน Jenkinsfile
sh 'ansible-playbook -i inventory playbook.yml'

# Ansible: รันเฉพาะ tag
ansible-playbook -i inventory playbook.yml --tags docker

# Jenkins: ใน Jenkinsfile
sh 'ansible-playbook -i inventory playbook.yml --tags docker'

# Ansible: check mode (dry run)
ansible-playbook -i inventory playbook.yml --check

# Jenkins: plan stage
stage('Dry Run') {
    steps { sh 'ansible-playbook -i inventory playbook.yml --check' }
}

# Ansible: ตัวแปร extra
ansible-playbook playbook.yml -e "env=production"

# Jenkins: parameters
parameters { string(name: 'ENV', defaultValue: 'production') }
```
