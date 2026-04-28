# ==============================================================================
# Compute - EC2 Instances สำหรับ Docker Swarm
# 3 ตัว: 1 manager + 2 workers
# Ansible จะ SSH เข้ามาติดตั้ง Docker + Swarm + Traefik + Portainer ทีหลัง
# ==============================================================================

# ── Manager Node ─────────────────────────────────────────────────────────────
# ทำหน้าที่: ควบคุม Swarm cluster + รัน Traefik & Portainer
resource "aws_instance" "manager" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
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
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.instances.id]

  tags = {
    Name = "${var.app_name}-${var.environment}-worker-${count.index + 1}"
    Role = "worker"
  }
}
