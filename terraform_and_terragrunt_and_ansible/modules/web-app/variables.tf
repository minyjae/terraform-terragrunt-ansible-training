# ==============================================================================
# Input Variables
# ==============================================================================

# ── General ───────────────────────────────────────────────────────────────────

variable "app_name" {
  description = "ชื่อ application ใช้เป็น prefix ตั้งชื่อทุก resource"
  type        = string
  default     = "web-app"
}

variable "environment" {
  description = "ชื่อ environment เช่น develop, staging, production"
  type        = string
}

# ── EC2 ───────────────────────────────────────────────────────────────────────

variable "ami" {
  description = "AMI ID สำหรับ EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "ขนาดของ EC2 instance เช่น t2.micro, t3.small"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "ชื่อ AWS Key Pair สำหรับ SSH เข้า EC2 (ต้องสร้างไว้ใน AWS ก่อน)"
  type        = string
}

# ── S3 ────────────────────────────────────────────────────────────────────────

variable "bucket_prefix" {
  description = "prefix ของชื่อ S3 bucket (Terraform จะเติมตัวสุ่มต่อท้าย)"
  type        = string
}

# ── RDS ───────────────────────────────────────────────────────────────────────

variable "db_name" {
  description = "ชื่อ database ที่จะสร้างภายใน RDS instance"
  type        = string
}

variable "db_user" {
  description = "username สำหรับเข้าถึง database"
  type        = string
}

variable "db_pass" {
  description = "password สำหรับเข้าถึง database"
  type        = string
  sensitive   = true
}
