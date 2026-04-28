# ==============================================================================
# Networking - VPC data, Security Groups
# เปิด ports สำหรับ SSH, Docker Swarm, Traefik, Portainer
# ==============================================================================

# ── ดึงข้อมูล Default VPC & Subnets ────────────────────────────────────────

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ── Security Group: EC2 Instances ──────────────────────────────────────────

resource "aws_security_group" "instances" {
  name   = "${var.app_name}-${var.environment}-instances"
  vpc_id = data.aws_vpc.default.id

  # ── SSH (Ansible ใช้ SSH เข้ามาติดตั้ง Docker + config ทั้งหมด) ──
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ── HTTP (Traefik รับ traffic) ──
  ingress {
    description = "HTTP - Traefik"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ── HTTPS (Traefik รับ traffic + auto SSL) ──
  ingress {
    description = "HTTPS - Traefik"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ── Traefik Dashboard (port 8080) ──
  ingress {
    description = "Traefik Dashboard"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ── Portainer UI (port 9443) ──
  ingress {
    description = "Portainer HTTPS UI"
    from_port   = 9443
    to_port     = 9443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ── Docker Swarm: Manager ↔ Worker communication ──
  # 2377 = cluster management
  # 7946 = node discovery (TCP+UDP)
  # 4789 = overlay network (UDP)
  ingress {
    description = "Swarm management"
    from_port   = 2377
    to_port     = 2377
    protocol    = "tcp"
    self        = true   # อนุญาตเฉพาะ instances ใน SG เดียวกัน
  }

  ingress {
    description = "Swarm node communication TCP"
    from_port   = 7946
    to_port     = 7946
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Swarm node communication UDP"
    from_port   = 7946
    to_port     = 7946
    protocol    = "udp"
    self        = true
  }

  ingress {
    description = "Swarm overlay network"
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    self        = true
  }

  # ── Outbound: ให้ออก internet ได้ (ดาวน์โหลด Docker, images) ──
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-sg"
  }
}
