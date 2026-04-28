###############################################################################
# Root Terragrunt Configuration
# ไฟล์นี้เป็น config กลางที่ทุก environment จะ include เข้าไป
# ทำหน้าที่ 2 อย่าง:
#   1. กำหนด Remote State Backend (S3 + DynamoDB) → ไม่ต้องเขียนซ้ำทุก module
#   2. Generate provider.tf อัตโนมัติ → ไม่ต้องเขียนซ้ำทุก module
###############################################################################

# ──────────────────────────────────────────────────────────────────────────────
# Remote State - เก็บ state file บน S3
# ──────────────────────────────────────────────────────────────────────────────
# Terragrunt จะ generate ไฟล์ backend.tf ให้อัตโนมัติในทุก module ที่ include
# ทำให้ไม่ต้องเขียน backend "s3" { ... } ซ้ำในทุกๆ module
remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"               # ชื่อไฟล์ที่จะ generate
    if_exists = "overwrite_terragrunt"     # ถ้ามีอยู่แล้วให้เขียนทับ
  }

  config = {
    bucket         = "devops-directive-tf-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    #                 ↑ สร้าง key อัตโนมัติจาก folder path
    #                 เช่น staging/web-app → "staging/web-app/terraform.tfstate"
    #                 เช่น production/web-app → "production/web-app/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Generate Provider - สร้าง provider.tf อัตโนมัติ
# ──────────────────────────────────────────────────────────────────────────────
# ทุก module ต้องมี provider config → Terragrunt generate ให้แทนการ copy-paste
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
        terraform {
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
        EOF
}
