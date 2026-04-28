# ==============================================================================
# Bootstrap - สร้าง S3 + DynamoDB สำหรับเก็บ Terraform State
# ==============================================================================
# ไฟล์นี้รันครั้งเดียวตอนเริ่มต้น project
# ใช้ local backend (เก็บ state ในเครื่อง) เพราะ S3 ยังไม่มี
#
# วิธีใช้:
#   cd 00-bootstrap
#   terraform init
#   terraform apply
# ==============================================================================

terraform {
  # ใช้ local backend เพราะ S3 bucket ยังไม่มี (เรากำลังจะสร้างมัน)
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

# ── S3 Bucket สำหรับเก็บ State File ──────────────────────────────────────

resource "aws_s3_bucket" "terraform_state" {
  bucket = "devops-directive-tf-state"

  tags = {
    Name      = "Terraform State"
    ManagedBy = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"   # เก็บทุก version ของ state file เผื่อต้องกู้คืน
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"   # เข้ารหัส state file (มี password อยู่ข้างใน)
    }
  }
}

# ── DynamoDB Table สำหรับ State Locking ──────────────────────────────────

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name      = "Terraform State Lock"
    ManagedBy = "terraform"
  }
}
