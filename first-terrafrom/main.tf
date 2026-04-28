###############################################################################
# Terraform Settings Block
# - block นี้ใช้สำหรับตั้งค่าพื้นฐานของ Terraform เช่น backend และ provider ที่ต้องการ
###############################################################################
terraform {

  ###########################################################################
  # Backend Block - กำหนดที่เก็บ State File ของ Terraform
  # - ใช้ S3 เป็นที่เก็บ state file เพื่อให้ทีมสามารถทำงานร่วมกันได้ (Remote State)
  ###########################################################################
  backend "s3" {
    bucket = "devops-testing"                  # ชื่อ S3 bucket ที่ใช้เก็บ state file
    key = "terraform/terraform.tfstate"        # path ของ state file ภายใน bucket
    region = "ap-southeast-1"                  # region ที่ S3 bucket ตั้งอยู่ (Singapore)
    dynamodb_table = "terraform-state-locking" # ชื่อ DynamoDB table สำหรับ state locking ป้องกันการแก้ไข state พร้อมกัน
    encrypt = true                             # เข้ารหัส state file ที่เก็บใน S3
  }

  ###########################################################################
  # Required Providers Block - กำหนด provider ที่จำเป็นต้องใช้
  ###########################################################################
  required_providers {
    aws = {
        source = "hashicorp/aws"   # แหล่งที่มาของ AWS provider (จาก HashiCorp Registry)
        version = "~> 6.0"        # ใช้ version 6.x (อนุญาต minor/patch update แต่ไม่อนุญาต major update)
    }
  }
}

###############################################################################
# Provider Block - ตั้งค่าการเชื่อมต่อกับ AWS
# - กำหนด region ที่จะสร้าง resource ทั้งหมด
###############################################################################
provider "aws" {
  region = "ap-southeast-1" # ใช้ region Singapore เป็น region หลัก
}

###############################################################################
# Data Source: AWS AMI - ค้นหา AMI (Amazon Machine Image) ล่าสุดของ Ubuntu
# - block นี้ไม่ได้สร้าง resource ใหม่ แต่เป็นการ "ดึงข้อมูล" AMI ที่มีอยู่แล้วมาใช้
###############################################################################
data "aws_ami" "latest_ubuntu" {
  most_recent = true                   # เลือก AMI ที่ใหม่ที่สุดจากผลลัพธ์ที่กรองได้
  owners      = ["099720109477"]       # หมายเลข Account ของ Canonical (บริษัทผู้สร้าง Ubuntu)

  # กรอง AMI ตามชื่อ - เลือกเฉพาะ Ubuntu 22.04 LTS (Jammy) แบบ amd64
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  # กรองเฉพาะ AMI ที่ใช้ virtualization แบบ HVM (Hardware Virtual Machine)
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

###############################################################################
# EC2 Instance #1 - สร้างเครื่อง EC2 ตัวที่ 1
# - block นี้สร้าง EC2 instance สำหรับ web server ที่แสดงข้อความ "Hello, World 1"
###############################################################################
resource "aws_instance" "terraform_instance_1" {
  ami = data.aws_ami.latest_ubuntu.id                    # ใช้ AMI ID ของ Ubuntu ล่าสุดที่ค้นหาจาก data source ด้านบน
  instance_type = "t2.micro"                             # ขนาดของ instance (1 vCPU, 1 GB RAM) - อยู่ใน Free Tier
  security_groups = [aws_security_group.instances.name]  # กำหนด Security Group ที่จะใช้กับ instance นี้
  user_data       = <<-EOF
              #!/bin/bash
              echo "Hello, World 1" > index.html
              python3 -m http.server 8080 &
              EOF
  # user_data = script ที่จะรันอัตโนมัติเมื่อ instance เริ่มทำงานครั้งแรก
  # - สร้างไฟล์ index.html ที่มีข้อความ "Hello, World 1"
  # - รัน Python HTTP server บน port 8080 เพื่อ serve ไฟล์ index.html
}

###############################################################################
# EC2 Instance #2 - สร้างเครื่อง EC2 ตัวที่ 2
# - block นี้สร้าง EC2 instance สำหรับ web server ที่แสดงข้อความ "Hello, World 2"
# - ใช้สำหรับ Load Balancing โดยกระจาย traffic ระหว่าง instance 1 และ 2
###############################################################################
resource "aws_instance" "terraform_instance_2" {
  ami = data.aws_ami.latest_ubuntu.id                    # ใช้ AMI ID ของ Ubuntu ล่าสุดที่ค้นหาจาก data source ด้านบน
  instance_type = "t2.micro"                             # ขนาดของ instance (1 vCPU, 1 GB RAM) - อยู่ใน Free Tier
  security_groups = [aws_security_group.instances.name]  # กำหนด Security Group ที่จะใช้กับ instance นี้
  user_data       = <<-EOF
              #!/bin/bash
              echo "Hello, World 2" > index.html
              python3 -m http.server 8080 &
              EOF
  # user_data = script ที่จะรันอัตโนมัติเมื่อ instance เริ่มทำงานครั้งแรก
  # - สร้างไฟล์ index.html ที่มีข้อความ "Hello, World 2"
  # - รัน Python HTTP server บน port 8080 เพื่อ serve ไฟล์ index.html
}

###############################################################################
# S3 Bucket - สร้าง S3 Bucket สำหรับเก็บไฟล์
# - block นี้สร้าง S3 bucket สำหรับเก็บข้อมูล/ไฟล์ของ application
###############################################################################
resource "aws_s3_bucket" "terraform_bucket" {
  bucket_prefix = "terraform-testing-devops" # prefix ของชื่อ bucket (Terraform จะเติมตัวอักษรสุ่มต่อท้ายให้ไม่ซ้ำกัน)
  force_destroy = true                       # อนุญาตให้ลบ bucket ได้แม้ยังมีไฟล์อยู่ข้างใน (ปกติ S3 ไม่ให้ลบถ้ายังมีไฟล์)
}

###############################################################################
# S3 Bucket Versioning - เปิดใช้ระบบ versioning ของ S3
# - block นี้เปิดการเก็บประวัติ version ของไฟล์ใน S3 bucket
# - ทำให้สามารถกู้คืนไฟล์เวอร์ชันเก่าได้หากเกิดการเขียนทับหรือลบโดยไม่ตั้งใจ
###############################################################################
resource "aws_s3_bucket_versioning" "terraform_bucket_versioning" {
  bucket = aws_s3_bucket.terraform_bucket.id # อ้างอิง bucket ID ที่จะเปิด versioning (เชื่อมกับ bucket ที่สร้างด้านบน)

  versioning_configuration {
    status = "Enabled" # สถานะของ versioning: "Enabled" = เปิดใช้งาน
  }
}

###############################################################################
# S3 Bucket Encryption - ตั้งค่าการเข้ารหัสไฟล์ใน S3
# - block นี้กำหนดให้ไฟล์ทุกไฟล์ที่ upload ขึ้น S3 ถูกเข้ารหัสอัตโนมัติ (Server-Side Encryption)
###############################################################################
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_crypto_conf" {
  bucket = aws_s3_bucket.bucket.bucket # อ้างอิงชื่อ bucket ที่ต้องการตั้งค่าการเข้ารหัส
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # ใช้อัลกอริทึม AES-256 ในการเข้ารหัส (Amazon S3-managed keys)
    }
  }
}

###############################################################################
# Data Source: Default VPC - ดึงข้อมูล VPC เริ่มต้นของ AWS Account
# - block นี้ดึงข้อมูล Default VPC ที่ AWS สร้างให้อัตโนมัติในทุก region
###############################################################################
data "aws_vpc" "default_vpc" {
  default = true # เลือก VPC ที่เป็น default VPC ของ account
}

###############################################################################
# Data Source: Default Subnets - ดึงข้อมูล Subnet ทั้งหมดใน Default VPC
# - block นี้ดึง subnet IDs ทั้งหมดใน default VPC เพื่อใช้กับ Load Balancer
###############################################################################
data "aws_subnet_ids" "default_subnet" {
  vpc_id = data.aws_vpc.default_vpc.id # ระบุ VPC ID เพื่อค้นหา subnet ใน VPC นั้น (ใช้ default VPC)
}

###############################################################################
# Security Group สำหรับ EC2 Instances
# - block นี้สร้าง Security Group (เสมือน firewall) สำหรับ EC2 instances
###############################################################################
resource "aws_security_group" "instances" {
  name = "instance-security-group" # ชื่อของ Security Group ที่จะแสดงใน AWS Console
}

###############################################################################
# Security Group Rule - อนุญาต HTTP Inbound Traffic สำหรับ EC2
# - block นี้สร้างกฎ firewall อนุญาตให้ traffic จากภายนอกเข้ามาที่ port 8080 ของ EC2
###############################################################################
resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"                        # ประเภทของ rule: "ingress" = ขาเข้า (traffic จากภายนอกเข้ามา)
  security_group_id = aws_security_group.instances.id  # อ้างอิง Security Group ที่จะเพิ่มกฎนี้

  from_port   = 8080          # port เริ่มต้นที่อนุญาต
  to_port     = 8080          # port สิ้นสุดที่อนุญาต (8080-8080 = เปิดแค่ port 8080 พอร์ตเดียว)
  protocol    = "tcp"         # protocol ที่อนุญาต: TCP
  cidr_blocks = ["0.0.0.0/0"] # อนุญาตจาก IP ทั้งหมด (0.0.0.0/0 = ทุก IP ในโลก)
}

###############################################################################
# ALB Listener - กำหนดการรับ traffic ของ Load Balancer
# - block นี้สร้าง listener บน ALB เพื่อรับ HTTP traffic ที่ port 80
###############################################################################
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.load_balancer.arn # อ้างอิง ARN ของ Load Balancer ที่ listener นี้จะผูกอยู่

  port = 80           # port ที่ listener จะรับ traffic (port 80 = HTTP มาตรฐาน)

  protocol = "HTTP"   # protocol ที่ใช้รับ traffic

  # default_action - การกระทำเริ่มต้นเมื่อไม่มี rule ใดตรงกับ request
  # ในกรณีนี้จะส่ง response กลับเป็น 404 page not found
  default_action {
    type = "fixed-response" # ประเภท action: ส่ง response คงที่กลับไปเลย (ไม่ forward ไปที่ใด)

    fixed_response {
      content_type = "text/plain"          # ประเภทเนื้อหาของ response
      message_body = "404: page not found" # ข้อความที่จะแสดง
      status_code  = 404                   # HTTP status code ที่จะส่งกลับ
    }
  }
}

###############################################################################
# ALB Target Group - กลุ่มเป้าหมายที่ Load Balancer จะส่ง traffic ไปหา
# - block นี้สร้าง target group สำหรับรวม EC2 instances ที่ ALB จะกระจาย traffic ไปให้
###############################################################################
resource "aws_lb_target_group" "instances" {
  name     = "example-target-group"        # ชื่อของ target group
  port     = 8080                          # port ที่จะส่ง traffic ไปยัง target (EC2 instances)
  protocol = "HTTP"                        # protocol ที่ใช้สื่อสารกับ target
  vpc_id   = data.aws_vpc.default_vpc.id   # VPC ที่ target group อยู่ (ต้องอยู่ใน VPC เดียวกับ targets)

  # Health Check - ตรวจสอบว่า target (EC2) ยังทำงานปกติหรือไม่
  health_check {
    path                = "/"      # URL path ที่ใช้ตรวจสอบ health
    protocol            = "HTTP"   # protocol ที่ใช้ตรวจ health
    matcher             = "200"    # HTTP status code ที่ถือว่า healthy (200 = OK)
    interval            = 15       # ตรวจ health ทุกกี่วินาที
    timeout             = 3        # รอ response นานสุดกี่วินาทีก่อนถือว่า timeout
    healthy_threshold   = 2        # ต้องตรวจผ่านกี่ครั้งติดต่อกันถึงจะถือว่า healthy
    unhealthy_threshold = 2        # ต้องตรวจไม่ผ่านกี่ครั้งติดต่อกันถึงจะถือว่า unhealthy
  }
}

###############################################################################
# Target Group Attachment #1 - ผูก EC2 Instance 1 เข้ากับ Target Group
# - block นี้ลงทะเบียน EC2 instance ตัวที่ 1 เข้ากับ target group ของ ALB
###############################################################################
resource "aws_lb_target_group_attachment" "instance_1" {
  target_group_arn = aws_lb_target_group.instances.arn  # ARN ของ target group ที่จะผูก instance เข้าไป
  target_id        = aws_instance.instance_1.id         # ID ของ EC2 instance ที่จะผูก
  port             = 8080                               # port ของ instance ที่ target group จะส่ง traffic ไปหา
}

###############################################################################
# Target Group Attachment #2 - ผูก EC2 Instance 2 เข้ากับ Target Group
# - block นี้ลงทะเบียน EC2 instance ตัวที่ 2 เข้ากับ target group ของ ALB
###############################################################################
resource "aws_lb_target_group_attachment" "instance_2" {
  target_group_arn = aws_lb_target_group.instances.arn  # ARN ของ target group ที่จะผูก instance เข้าไป
  target_id        = aws_instance.instance_2.id         # ID ของ EC2 instance ที่จะผูก
  port             = 8080                               # port ของ instance ที่ target group จะส่ง traffic ไปหา
}

###############################################################################
# ALB Listener Rule - กฎการ routing ของ listener
# - block นี้สร้างกฎให้ listener ส่ง traffic ทุก request ไปยัง target group (EC2 instances)
###############################################################################
resource "aws_lb_listener_rule" "instances" {
  listener_arn = aws_lb_listener.http.arn # ARN ของ listener ที่จะเพิ่มกฎนี้
  priority     = 100                      # ลำดับความสำคัญของกฎ (ตัวเลขน้อย = สำคัญกว่า)

  # condition - เงื่อนไขที่ต้องตรงจึงจะใช้กฎนี้
  condition {
    path_pattern {
      values = ["*"] # จับคู่ทุก URL path (* = wildcard ทุก path)
    }
  }

  # action - สิ่งที่จะทำเมื่อเงื่อนไขตรง
  action {
    type             = "forward"                          # ประเภท action: ส่งต่อ (forward) traffic
    target_group_arn = aws_lb_target_group.instances.arn  # ส่งไปยัง target group ที่มี EC2 instances
  }
}

###############################################################################
# Security Group สำหรับ ALB (Application Load Balancer)
# - block นี้สร้าง Security Group สำหรับ Load Balancer แยกจาก EC2 instances
###############################################################################
resource "aws_security_group" "alb" {
  name = "alb-security-group" # ชื่อของ Security Group สำหรับ ALB
}

###############################################################################
# Security Group Rule - อนุญาต HTTP Inbound สำหรับ ALB
# - block นี้อนุญาตให้ traffic จากภายนอกเข้ามาที่ port 80 ของ ALB
###############################################################################
resource "aws_security_group_rule" "allow_alb_http_inbound" {
  type              = "ingress"                    # ประเภท: ขาเข้า
  security_group_id = aws_security_group.alb.id    # อ้างอิง Security Group ของ ALB

  from_port   = 80             # port เริ่มต้น
  to_port     = 80             # port สิ้นสุด (เปิดแค่ port 80)
  protocol    = "tcp"          # protocol: TCP
  cidr_blocks = ["0.0.0.0/0"]  # อนุญาตจากทุก IP

}

###############################################################################
# Security Group Rule - อนุญาต Outbound Traffic ทั้งหมดสำหรับ ALB
# - block นี้อนุญาตให้ ALB ส่ง traffic ออกไปได้ทุก port, ทุก protocol
# - จำเป็นเพื่อให้ ALB สามารถส่ง traffic ไปยัง EC2 instances (port 8080) ได้
###############################################################################
resource "aws_security_group_rule" "allow_alb_all_outbound" {
  type              = "egress"                     # ประเภท: ขาออก
  security_group_id = aws_security_group.alb.id    # อ้างอิง Security Group ของ ALB

  from_port   = 0              # port เริ่มต้น (0 = ทุก port)
  to_port     = 0              # port สิ้นสุด (0 = ทุก port)
  protocol    = "-1"           # protocol: "-1" = ทุก protocol (TCP, UDP, ICMP ฯลฯ)
  cidr_blocks = ["0.0.0.0/0"]  # อนุญาตส่งไปทุก IP

}


###############################################################################
# Application Load Balancer (ALB) - สร้าง Load Balancer
# - block นี้สร้าง ALB สำหรับกระจาย traffic ไปยัง EC2 instances หลายตัว
# - ทำให้ระบบมี High Availability และรองรับ traffic ได้มากขึ้น
###############################################################################
resource "aws_lb" "load_balancer" {
  name               = "web-app-lb"                            # ชื่อของ Load Balancer
  load_balancer_type = "application"                           # ประเภท: Application LB (ทำงานที่ Layer 7 - HTTP/HTTPS)
  subnets            = data.aws_subnet_ids.default_subnet.ids  # subnet ที่ ALB จะทำงาน (ต้องมีอย่างน้อย 2 AZ)
  security_groups    = [aws_security_group.alb.id]             # Security Group ที่ใช้กับ ALB

}

###############################################################################
# Route53 Hosted Zone - สร้างโซน DNS สำหรับโดเมน
# - block นี้สร้าง hosted zone ใน Route53 เพื่อจัดการ DNS records ของโดเมน
###############################################################################
resource "aws_route53_zone" "primary" {
  name = "devopsdeployed.com" # ชื่อโดเมนที่ต้องการจัดการ DNS
}

###############################################################################
# Route53 Record - สร้าง DNS Record ชี้โดเมนไปยัง ALB
# - block นี้สร้าง A record (Alias) เพื่อชี้โดเมนไปที่ Load Balancer
# - ทำให้ user เข้าเว็บผ่านชื่อโดเมนแทน IP address ของ ALB
###############################################################################
resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.primary.zone_id # ID ของ hosted zone ที่จะเพิ่ม record
  name    = "devopsdeployed.com"             # ชื่อ DNS record (ชื่อโดเมน)
  type    = "A"                              # ประเภท record: A record (ชี้ไป IP address)

  # alias block - ใช้ Alias record แทน A record ปกติ (เฉพาะ AWS resources)
  # Alias record ไม่เสียค่า query fee และรองรับ health check
  alias {
    name                   = aws_lb.load_balancer.dns_name  # DNS name ของ ALB ที่จะชี้ไป
    zone_id                = aws_lb.load_balancer.zone_id   # Hosted Zone ID ของ ALB (AWS กำหนดให้)
    evaluate_target_health = true                           # ตรวจสอบ health ของ target (ALB) ก่อน resolve DNS
  }
}

###############################################################################
# RDS Database Instance - สร้าง Database Server (PostgreSQL)
# - block นี้สร้าง RDS instance สำหรับเป็น database ของ application
# - ใช้ PostgreSQL engine
###############################################################################
resource "aws_db_instance" "db_instance" {
  allocated_storage = 20                 # ขนาดพื้นที่เก็บข้อมูล (หน่วย: GB)
  # auto_minor_version_upgrade อนุญาตให้ AWS อัปเกรด minor version อัตโนมัติ
  # เช่น จาก 12.7 เป็น 12.8 - ช่วยให้ได้รับ security patch ใหม่ๆ
  # แต่ใน production จริงอาจเสี่ยงเกินไป ควรทดสอบก่อน upgrade
  auto_minor_version_upgrade = true      # เปิดการอัปเกรด minor version อัตโนมัติ
  storage_type               = "standard" # ประเภท storage: "standard" = Magnetic (ราคาถูก, ช้ากว่า SSD)
  engine                     = "postgres" # database engine ที่ใช้: PostgreSQL
  engine_version             = "12"       # version หลักของ PostgreSQL
  instance_class             = "db.t2.micro" # ขนาดของ DB instance (1 vCPU, 1 GB RAM) - Free Tier
  db_name                    = "mydb"     # ชื่อ database เริ่มต้นที่จะสร้างใน instance
  username                   = "foo"      # ชื่อ master username สำหรับเข้าถึง database
  password                   = "foobarbaz" # รหัสผ่าน master user (⚠️ ไม่ควร hardcode ใน production ควรใช้ variables หรือ secrets manager)
  skip_final_snapshot        = true       # ข้าม final snapshot เมื่อลบ DB (ปกติ AWS จะบังคับให้สร้าง snapshot ก่อนลบ)
}
