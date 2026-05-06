# ==============================================================================
# Compute - EC2 Instances สำหรับ Docker Swarm
# 3 ตัว: 1 manager + 2 workers
# Ansible จะ SSH เข้ามาติดตั้ง Docker + Swarm + Traefik + Portainer ทีหลัง
# ==============================================================================

data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── Manager Node ─────────────────────────────────────────────────────────────
# ทำหน้าที่: ควบคุม Swarm cluster + รัน Traefik & Portainer
resource "aws_instance" "manager" {
  ami                    = data.aws_ami.latest_ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.instances.id]

  tags = {
    Name = "${var.app_name}-${var.environment}-manager"
    Role = "manager"
  }
}

# ── Worker Nodes ─────────────────────────────────────────────────────────────
# ทำหน้าที่: รัน application containers
resource "aws_instance" "worker" {
  count                  = 2
  ami                    = data.aws_ami.latest_ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.instances.id]

  tags = {
    Name = "${var.app_name}-${var.environment}-worker-${count.index + 1}"
    Role = "worker"
  }
}

# ── Generate Ansible Inventory ──────────────────────────────────────────────
# สร้างไฟล์ inventory.yml สำหรับ Ansible อัตโนมัติหลังสร้าง instances เสร็จ
# ── Generate Ansible Inventory ──────────────────────────────────────────────
# สร้างไฟล์ inventory.yml สำหรับ Ansible อัตโนมัติหลังสร้าง instances เสร็จ
resource "local_file" "ansible_inventory" {
  # บังคับให้รอสร้าง EC2 เสร็จก่อน
  depends_on = [aws_instance.manager, aws_instance.worker]

  # ระบุ Path และชื่อไฟล์ที่ต้องการให้สร้าง
  filename = "../../../../ansible/inventories/dev/inventory.yml"

  # ใช้ <<-EOT เพื่อเขียนข้อความหลายบรรทัด และฝังตัวแปร Terraform ลงไปได้เลย
  content = <<-EOT
all:
  vars:
    project_name: ${var.app_name}-${var.environment}
    env_name: ${var.environment}
    aws_region: ap-southeast-1
    cloud_provider: aws

  children:
    docker_swarm:
      children:
        docker_swarm_managers:
          hosts:
            manager-01:
              ansible_host: ${aws_instance.manager.public_ip}
              ansible_user: ubuntu
              private_ip: ${aws_instance.manager.private_ip}
              public_ip: ${aws_instance.manager.public_ip}
              node_role: manager
              is_primary_manager: true

        docker_swarm_workers:
          hosts:
%{ for index, worker in aws_instance.worker ~}
            worker-0${index + 1}:
              ansible_host: ${worker.public_ip}
              ansible_user: ubuntu
              private_ip: ${worker.private_ip}
              public_ip: ${worker.public_ip}
              node_role: worker
              is_primary_manager: false
%{ endfor ~}
EOT
}
