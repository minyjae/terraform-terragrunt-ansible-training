# Terraform Workshop - Complete Guide

> คู่มืออธิบาย Workshop จากคอร์ส `devops-directive-terraform-course` อย่างละเอียด
> พร้อมแนวทางการใช้ Terragrunt และการสร้าง Web Application Infrastructure ตั้งแต่เริ่มต้น

---

## สารบัญ

1. [ภาพรวมของ Workshop ทั้งหมด](#1-ภาพรวมของ-workshop-ทั้งหมด)
2. [Lesson 01 - Cloud & Infrastructure as Code](#2-lesson-01---cloud--infrastructure-as-code)
3. [Lesson 02 - Overview & Setup](#3-lesson-02---overview--setup)
4. [Lesson 03 - Basics (State & Web App)](#4-lesson-03---basics)
5. [Lesson 04 - Variables & Outputs](#5-lesson-04---variables--outputs)
6. [Lesson 05 - Language Features (HCL)](#6-lesson-05---language-features)
7. [Lesson 06 - Organization & Modules](#7-lesson-06---organization--modules)
8. [Lesson 07 - Managing Multiple Environments](#8-lesson-07---managing-multiple-environments)
9. [Lesson 08 - Testing Terraform](#9-lesson-08---testing-terraform)
10. [Lesson 09 - Developer Workflows & CI/CD](#10-lesson-09---developer-workflows--cicd)
11. [Terragrunt คืออะไร และช่วย Terraform ได้อย่างไร](#11-terragrunt-คืออะไร-และช่วย-terraform-ได้อย่างไร)
12. [การสร้าง Web App Infrastructure ตั้งแต่เริ่มต้น](#12-การสร้าง-web-app-infrastructure-ตั้งแต่เริ่มต้น)

---

## 1. ภาพรวมของ Workshop ทั้งหมด

Workshop นี้สอน Terraform ตั้งแต่ระดับเริ่มต้นจนถึงระดับ Production โดยค่อยๆ สร้าง Web Application บน AWS
แต่ละ lesson จะเพิ่มความซับซ้อนขึ้นเรื่อยๆ:

```
Lesson 01: ทฤษฎี (Cloud & IaC คืออะไร)
    │
Lesson 02: เริ่มต้นเขียน Terraform (สร้าง EC2 1 ตัว)
    │
Lesson 03: Remote State + สร้าง Web App เต็มรูปแบบ (EC2, ALB, RDS, S3, DNS)
    │
Lesson 04: ปรับปรุงโค้ดด้วย Variables & Outputs (ยืดหยุ่นขึ้น)
    │
Lesson 05: เรียนรู้ HCL ลึกขึ้น (conditionals, loops, functions)
    │
Lesson 06: จัดโครงสร้างโค้ดด้วย Modules (reusable)
    │
Lesson 07: จัดการหลาย Environment (staging/production)
    │
Lesson 08: Testing Terraform (static analysis + integration test)
    │
Lesson 09: CI/CD & Team Workflows
```

---

## 2. Lesson 01 - Cloud & Infrastructure as Code

### สิ่งที่สอน
- **ทฤษฎีพื้นฐาน** - ไม่มีโค้ด
- อธิบายว่า Cloud Computing คืออะไร
- ทำไมต้อง Infrastructure as Code (IaC)
- เปรียบเทียบเครื่องมือ IaC ต่างๆ: Terraform vs CloudFormation vs Pulumi vs CDK
- ทำไม Terraform จึงเป็นที่นิยม: Multi-cloud, Declarative, State Management

### สิ่งที่ควรเข้าใจก่อนไปต่อ
| หัวข้อ | ความหมาย |
|--------|----------|
| IaC | การเขียนโค้ดเพื่อสร้าง/จัดการ infrastructure แทนการ click ผ่าน console |
| Declarative | เราบอกว่า "ต้องการอะไร" ไม่ใช่ "ทำอย่างไร" |
| State | Terraform เก็บสถานะของ infrastructure ไว้ในไฟล์ เพื่อรู้ว่าอะไรมีอยู่แล้ว อะไรต้องสร้างใหม่ |
| Provider | ตัวเชื่อมต่อกับ Cloud (AWS, GCP, Azure) |

---

## 3. Lesson 02 - Overview & Setup

### สิ่งที่สอน
สร้าง resource แรก - EC2 instance 1 ตัว แบบง่ายที่สุด

### โค้ดและอธิบาย

```hcl
# 02-overview/main.tf

# กำหนดว่าจะใช้ provider อะไร version อะไร
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"  # ดึง AWS provider จาก HashiCorp Registry
      version = "~> 3.0"        # ใช้ version 3.x
    }
  }
}

# ตั้งค่าการเชื่อมต่อ AWS
provider "aws" {
  region = "us-east-1"  # สร้าง resource ใน region US East (N. Virginia)
}

# สร้าง EC2 instance 1 ตัว
resource "aws_instance" "example" {
  ami           = "ami-011899242bb902164"  # Ubuntu 20.04 LTS AMI ID
  instance_type = "t2.micro"              # ขนาดเล็กสุด (Free Tier)
}
```

### สิ่งที่ได้เรียนรู้
1. **terraform init** - ดาวน์โหลด provider plugins
2. **terraform plan** - ดูว่าจะสร้าง/เปลี่ยนอะไรบ้าง (dry-run)
3. **terraform apply** - สร้าง resource จริง
4. **terraform destroy** - ทำลาย resource ทั้งหมด
5. State file ถูกเก็บไว้ local (`terraform.tfstate`) ← ยังไม่ใช่ best practice

### ปัญหาที่ยังมี
- State เก็บไว้ในเครื่อง ← ทำงานเป็นทีมไม่ได้
- AMI ID hardcode ← เปลี่ยน region แล้วพัง
- ไม่มี variables ← ปรับแต่งยาก

---

## 4. Lesson 03 - Basics

### สิ่งที่สอน
2 เรื่องหลัก:
1. **Remote State Backend** - เก็บ state file บน S3 + ใช้ DynamoDB ทำ state locking
2. **Web App Architecture** - สร้าง web application เต็มรูปแบบ

---

### 03-A: AWS Backend (`aws-backend/`)

**เป้าหมาย**: สร้างที่เก็บ State File บน AWS

```hcl
# สร้าง S3 Bucket สำหรับเก็บ state file
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "devops-directive-tf-state"  # ชื่อ bucket (ต้องไม่ซ้ำทั่วโลก)
  force_destroy = true                         # ลบ bucket ได้แม้มีไฟล์ข้างใน
}

# เปิด versioning เพื่อเก็บประวัติ state file ทุก version
resource "aws_s3_bucket_versioning" "terraform_bucket_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"  # ← สำคัญ! ถ้า state file พังสามารถย้อนกลับได้
  }
}

# เข้ารหัส state file (state file มีข้อมูล sensitive เช่น password)
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_crypto_conf" {
  bucket = aws_s3_bucket.terraform_state.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"  # เข้ารหัสด้วย AES-256
    }
  }
}

# สร้าง DynamoDB Table สำหรับ State Locking
# ← ป้องกันไม่ให้ 2 คนรัน terraform apply พร้อมกัน
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"  # จ่ายตามการใช้งาน (ไม่ต้อง provision capacity)
  hash_key     = "LockID"           # Primary key ที่ Terraform ใช้ lock

  attribute {
    name = "LockID"
    type = "S"  # String type
  }
}
```

**ขั้นตอนการใช้งาน (Chicken-and-Egg Problem):**
1. รัน `terraform apply` ด้วย local backend ก่อน → สร้าง S3 + DynamoDB
2. เพิ่ม `backend "s3" { ... }` block
3. รัน `terraform init` ใหม่ → Terraform จะถามว่าจะย้าย state จาก local ไป S3 ไหม → ตอบ yes

---

### 03-B: Web App (`web-app/`)

**เป้าหมาย**: สร้าง Web Application เต็มรูปแบบ

**Architecture ที่สร้าง:**
```
User → Route53 (DNS) → ALB (Load Balancer) → EC2 Instance 1 (port 8080)
                                             → EC2 Instance 2 (port 8080)

                        S3 Bucket (เก็บข้อมูล)
                        RDS PostgreSQL (Database)
```

**Resource ทั้งหมดที่สร้าง (17 resources):**

| # | Resource | ทำหน้าที่ |
|---|----------|----------|
| 1 | `aws_instance` x2 | EC2 server รัน web app |
| 2 | `aws_s3_bucket` | เก็บข้อมูล/ไฟล์ |
| 3 | `aws_s3_bucket_versioning` | เปิด versioning ของ S3 |
| 4 | `aws_s3_bucket_server_side_encryption_configuration` | เข้ารหัสไฟล์ใน S3 |
| 5 | `aws_security_group` (instances) | Firewall สำหรับ EC2 |
| 6 | `aws_security_group_rule` (http inbound) | เปิด port 8080 ให้ EC2 |
| 7 | `aws_lb` | Application Load Balancer |
| 8 | `aws_lb_listener` | รับ traffic port 80 |
| 9 | `aws_lb_target_group` | กลุ่มเป้าหมาย (EC2 instances) |
| 10 | `aws_lb_target_group_attachment` x2 | ผูก EC2 เข้า target group |
| 11 | `aws_lb_listener_rule` | กฎ routing → forward ไป target group |
| 12 | `aws_security_group` (alb) | Firewall สำหรับ ALB |
| 13 | `aws_security_group_rule` (alb inbound) | เปิด port 80 ให้ ALB |
| 14 | `aws_security_group_rule` (alb outbound) | ให้ ALB ส่ง traffic ออกได้ |
| 15 | `aws_route53_zone` | DNS zone |
| 16 | `aws_route53_record` | A record ชี้ไป ALB |
| 17 | `aws_db_instance` | PostgreSQL database |

### ปัญหาที่ยังมี
- AMI, instance_type, domain, db password ยัง **hardcode** อยู่ในโค้ด
- ไม่มี output → ไม่รู้ว่า resource ที่สร้างมี IP/endpoint อะไร
- ใช้โค้ดซ้ำไม่ได้ → ต้อง copy-paste ทั้งไฟล์ถ้าจะสร้างอีก app

---

## 5. Lesson 04 - Variables & Outputs

### สิ่งที่สอน
แก้ปัญหา hardcode ด้วย **Variables** (input) และ **Outputs** (output)

---

### 04-A: Examples (`examples/`)

**เป้าหมาย**: สาธิตการใช้ variable แบบต่างๆ

```hcl
# variables.tf - ประกาศตัวแปร

# variable ที่มี default (ไม่จำเป็นต้องระบุค่าตอน apply)
variable "instance_type" {
  description = "ec2 instance type"
  type        = string
  default     = "t2.micro"
}

# variable ที่ไม่มี default (ต้องระบุค่าตอน apply ไม่งั้นจะถาม)
variable "instance_name" {
  description = "Name of ec2 instance"
  type        = string
}

# variable ที่เป็น sensitive (ไม่แสดงค่าใน log)
variable "db_pass" {
  description = "Password for DB"
  type        = string
  sensitive   = true  # ← Terraform จะไม่แสดงค่าตัวแปรนี้ใน output/plan
}
```

**วิธีส่งค่า variable (4 วิธี ตามลำดับความสำคัญ):**

```bash
# วิธีที่ 1: ผ่าน command line flag
terraform apply -var="db_pass=mypassword"

# วิธีที่ 2: ผ่าน .tfvars file (auto-load ถ้าชื่อ terraform.tfvars)
# terraform.tfvars
# db_pass = "mypassword"

# วิธีที่ 3: ผ่าน .tfvars file อื่น (ต้องระบุ -var-file)
terraform apply -var-file="another-variable-file.tfvars"

# วิธีที่ 4: ผ่าน environment variable (prefix TF_VAR_)
export TF_VAR_db_pass="mypassword"
```

**ลำดับความสำคัญ (สูง → ต่ำ):**
`-var flag` > `-var-file` > `terraform.tfvars` > `TF_VAR_` env > `default`

---

### 04-B: Web App with Variables (`web-app/`)

**เป้าหมาย**: Refactor web app จาก Lesson 03 ให้ใช้ variables

**ก่อน (Lesson 03) - Hardcode:**
```hcl
resource "aws_instance" "instance_1" {
  ami           = "ami-011899242bb902164"  # ← hardcode!
  instance_type = "t2.micro"              # ← hardcode!
}

resource "aws_route53_zone" "primary" {
  name = "devopsdeployed.com"  # ← hardcode!
}

resource "aws_db_instance" "db_instance" {
  password = "foobarbaz"  # ← hardcode! อันตราย!
}
```

**หลัง (Lesson 04) - ใช้ Variables:**
```hcl
# variables.tf
variable "ami" {
  description = "Amazon machine image to use for ec2 instance"
  type        = string
  default     = "ami-011899242bb902164"
}

variable "domain" {
  description = "Domain for website"
  type        = string
}

variable "db_pass" {
  description = "Password for DB"
  type        = string
  sensitive   = true  # ← ซ่อนค่า password จาก log
}

# main.tf - ใช้ var.xxx แทน hardcode
resource "aws_instance" "instance_1" {
  ami           = var.ami            # ← ใช้ variable
  instance_type = var.instance_type  # ← ใช้ variable
}

resource "aws_route53_zone" "primary" {
  name = var.domain  # ← ใช้ variable
}

resource "aws_db_instance" "db_instance" {
  password = var.db_pass  # ← ใช้ variable + sensitive
}
```

**outputs.tf - แสดงค่าที่สำคัญหลัง apply:**
```hcl
output "instance_1_ip_addr" {
  value = aws_instance.instance_1.public_ip  # ← แสดง IP ของ EC2 หลัง apply
}

output "db_instance_addr" {
  value = aws_db_instance.db_instance.address  # ← แสดง endpoint ของ DB
}
```

**terraform.tfvars - ค่าจริงที่ใช้:**
```hcl
bucket_prefix = "devops-directive-web-app-data"
domain        = "devopsdeployed.com"
db_name       = "mydb"
db_user       = "foo"
# db_pass = "foobarbaz"  ← comment ไว้เพราะไม่ควร commit password
```

### สิ่งที่ได้เรียนรู้
- แยก configuration ออกจาก code → เปลี่ยนค่าได้โดยไม่แก้โค้ด
- ใช้ `sensitive = true` ป้องกัน password หลุด
- ใช้ `outputs` เพื่อดึงข้อมูลสำคัญออกมาใช้ต่อ
- ใช้ `.tfvars` file จัดการค่า variable

---

## 6. Lesson 05 - Language Features

### สิ่งที่สอน
เรียนรู้ HCL (HashiCorp Configuration Language) อย่างลึกซึ้ง - ไม่มีโค้ดตัวอย่างแยก แต่เป็น reference

### หัวข้อสำคัญ

**1. Conditionals (เงื่อนไข):**
```hcl
# syntax: condition ? true_value : false_value
resource "aws_route53_zone" "primary" {
  count = var.create_dns_zone ? 1 : 0  # สร้าง DNS zone เฉพาะเมื่อ create_dns_zone = true
  name  = var.domain
}
```

**2. count & for_each (สร้าง resource หลายตัว):**
```hcl
# count - สร้าง 3 instances
resource "aws_instance" "server" {
  count         = 3
  ami           = "ami-xxx"
  instance_type = "t2.micro"
  tags = {
    Name = "Server-${count.index}"  # Server-0, Server-1, Server-2
  }
}

# for_each - สร้างจาก map
resource "aws_instance" "server" {
  for_each      = toset(["web", "api", "worker"])
  ami           = "ami-xxx"
  instance_type = "t2.micro"
  tags = {
    Name = "Server-${each.key}"  # Server-web, Server-api, Server-worker
  }
}
```

**3. locals (ตัวแปร local):**
```hcl
locals {
  environment_name = "staging"
  subdomain = var.environment_name == "production" ? "" : "${var.environment_name}."
  # production → ""  (เข้าผ่าน devopsdeployed.com)
  # staging    → "staging."  (เข้าผ่าน staging.devopsdeployed.com)
}
```

**4. Lifecycle meta-arguments:**
```hcl
resource "aws_instance" "example" {
  # ...
  lifecycle {
    create_before_destroy = true   # สร้างตัวใหม่ก่อน แล้วค่อยลบตัวเก่า
    ignore_changes        = [ami]  # ไม่สนใจการเปลี่ยน AMI (ไม่ recreate)
    prevent_destroy       = true   # ป้องกันการลบ resource นี้
  }
}
```

**5. Built-in Functions ที่ใช้บ่อย:**
| Function | ตัวอย่าง | ผลลัพธ์ |
|----------|---------|---------|
| `upper()` | `upper("hello")` | `"HELLO"` |
| `lower()` | `lower("HELLO")` | `"hello"` |
| `join()` | `join(",", ["a","b","c"])` | `"a,b,c"` |
| `split()` | `split(",", "a,b,c")` | `["a","b","c"]` |
| `length()` | `length(["a","b"])` | `2` |
| `lookup()` | `lookup({a=1}, "a", 0)` | `1` |
| `file()` | `file("script.sh")` | อ่านไฟล์ |
| `templatefile()` | `templatefile("tmpl.tpl", {name="x"})` | render template |
| `toset()` | `toset(["a","b","a"])` | `["a","b"]` |

---

## 7. Lesson 06 - Organization & Modules

### สิ่งที่สอน
จัดโครงสร้างโค้ดให้ **reusable** ด้วย Terraform Modules

### ปัญหาก่อนใช้ Module
```
web-app/
  └── main.tf  ← ไฟล์เดียว 220+ บรรทัด ทำทุกอย่าง
                  ถ้าจะสร้าง web app อีกตัว → copy-paste ทั้งไฟล์
                  ถ้าจะแก้ bug → แก้ทุกที่ที่ copy ไป
```

### การแก้ปัญหาด้วย Module

**โครงสร้าง Module (`web-app-module/`):**
```
web-app-module/
  ├── main.tf         ← required_providers (ไม่มี backend, ไม่มี provider)
  ├── variables.tf    ← input variables
  ├── outputs.tf      ← output values
  ├── compute.tf      ← EC2 instances
  ├── networking.tf   ← ALB, Security Groups, Target Groups
  ├── storage.tf      ← S3 Bucket
  ├── database.tf     ← RDS PostgreSQL
  └── dns.tf          ← Route53 DNS
```

**หลักการแยกไฟล์:**
- `main.tf` - เฉพาะ terraform settings (ไม่มี backend/provider เพราะ caller กำหนดเอง)
- แยกไฟล์ตาม **ประเภท resource** → อ่านง่าย หาง่าย
- `variables.tf` - รวม input ทั้งหมดไว้ที่เดียว
- `outputs.tf` - รวม output ทั้งหมดไว้ที่เดียว

**สิ่งที่น่าสนใจใน `dns.tf` - การใช้ conditional:**
```hcl
# สร้าง zone ใหม่เฉพาะเมื่อ create_dns_zone = true (เช่น production)
resource "aws_route53_zone" "primary" {
  count = var.create_dns_zone ? 1 : 0
  name  = var.domain
}

# ดึง zone ที่มีอยู่แล้วเมื่อ create_dns_zone = false (เช่น staging)
data "aws_route53_zone" "primary" {
  count = var.create_dns_zone ? 0 : 1
  name  = var.domain
}

# ใช้ locals เลือกว่าจะใช้ zone_id จากไหน
locals {
  dns_zone_id = var.create_dns_zone ? aws_route53_zone.primary[0].zone_id : data.aws_route53_zone.primary[0].zone_id
  # production → domain.com  / staging → staging.domain.com
  subdomain   = var.environment_name == "production" ? "" : "${var.environment_name}."
}

# สร้าง DNS record ด้วย subdomain ที่เหมาะสม
resource "aws_route53_record" "root" {
  zone_id = local.dns_zone_id
  name    = "${local.subdomain}${var.domain}"  # staging.devopsdeployed.com
  type    = "A"
  alias { ... }
}
```

**สิ่งที่น่าสนใจใน `networking.tf` - Dynamic naming:**
```hcl
# ใช้ interpolation สร้างชื่อที่ไม่ซ้ำกันระหว่าง environments
resource "aws_security_group" "instances" {
  name = "${var.app_name}-${var.environment_name}-instance-security-group"
  # → "web-app-production-instance-security-group"
  # → "web-app-staging-instance-security-group"
}

resource "aws_lb" "load_balancer" {
  name = "${var.app_name}-${var.environment_name}-web-app-lb"
  # → "web-app-production-web-app-lb"
}
```

---

### การเรียกใช้ Module (`web-app/main.tf`)

```hcl
# สร้าง web app ตัวที่ 1
module "web_app_1" {
  source = "../web-app-module"  # ← path ไปยัง module

  # ส่งค่า variables เข้าไปใน module
  bucket_prefix    = "web-app-1-data"
  domain           = "devopsdeployed.com"
  app_name         = "web-app-1"
  environment_name = "production"
  instance_type    = "t2.micro"
  create_dns_zone  = true        # ← สร้าง DNS zone ใหม่
  db_name          = "webapp1db"
  db_user          = "foo"
  db_pass          = var.db_pass_1
}

# สร้าง web app ตัวที่ 2 (ต่างโดเมน)
module "web_app_2" {
  source = "../web-app-module"  # ← ใช้ module เดียวกัน!

  bucket_prefix    = "web-app-2-data"
  domain           = "anotherdevopsdeployed.com"  # ← โดเมนต่างกัน
  app_name         = "web-app-2"
  environment_name = "production"
  instance_type    = "t2.micro"
  create_dns_zone  = true
  db_name          = "webapp2db"
  db_user          = "bar"
  db_pass          = var.db_pass_2
}
```

**ข้อดีที่เห็นได้ชัด:**
- เขียน module ครั้งเดียว สร้าง web app ได้ไม่จำกัดจำนวน
- แก้ bug ที่ module → ทุก web app ได้รับการแก้ไข
- แต่ละ web app มี configuration เป็นของตัวเอง

---

## 8. Lesson 07 - Managing Multiple Environments

### สิ่งที่สอน
2 วิธีในการจัดการหลาย environment (dev/staging/production)

---

### วิธีที่ 1: File Structure (แนะนำ)

**โครงสร้าง:**
```
file-structure/
  ├── global/
  │   └── main.tf       ← resource ที่ share กันทุก env (DNS zone)
  ├── staging/
  │   └── main.tf       ← staging environment
  └── production/
      └── main.tf       ← production environment
```

**global/main.tf - Resource ที่ share ข้าม environment:**
```hcl
# DNS zone สร้างครั้งเดียว share กันทุก environment
resource "aws_route53_zone" "primary" {
  name = "devopsdeployed.com"
}
```

**staging/main.tf:**
```hcl
terraform {
  backend "s3" {
    # ← state file แยกกันระหว่าง staging กับ production
    key = "07-managing-multiple-environments/staging/terraform.tfstate"
  }
}

locals {
  environment_name = "staging"
}

module "web_app" {
  source = "../../../06-organization-and-modules/web-app-module"

  bucket_prefix    = "web-app-data-${local.environment_name}"
  domain           = "devopsdeployed.com"
  environment_name = local.environment_name   # "staging"
  instance_type    = "t2.micro"               # ← staging ใช้เครื่องเล็ก
  create_dns_zone  = false                    # ← ไม่สร้าง zone ใหม่ (ใช้จาก global)
  db_name          = "${local.environment_name}mydb"  # "stagingmydb"
  db_user          = "foo"
  db_pass          = var.db_pass
}
```

**production/main.tf:**
```hcl
terraform {
  backend "s3" {
    key = "07-managing-multiple-environments/production/terraform.tfstate"
    #                                        ^^^^^^^^^^ state file คนละตัว!
  }
}

locals {
  environment_name = "production"
}

module "web_app" {
  source = "../../../06-organization-and-modules/web-app-module"

  bucket_prefix    = "web-app-data-${local.environment_name}"
  domain           = "devopsdeployed.com"
  environment_name = local.environment_name   # "production"
  instance_type    = "t2.micro"               # ← production อาจใช้เครื่องใหญ่กว่า
  create_dns_zone  = false
  db_name          = "${local.environment_name}mydb"  # "productionmydb"
  db_user          = "foo"
  db_pass          = var.db_pass
}
```

**ข้อดี:**
- State file แยกกัน → staging พังไม่กระทบ production
- สามารถ apply แยกอิสระ: `cd staging && terraform apply`
- เห็นความแตกต่างระหว่าง env ชัดเจน
- เหมาะกับทีมใหญ่

**ข้อเสีย:**
- Code ซ้ำกันระหว่าง staging/production (แม้จะใช้ module)
- ต้องอัปเดตทุก env ทีละตัว

---

### วิธีที่ 2: Workspaces

**โครงสร้าง:**
```
workspaces/
  └── main.tf  ← ไฟล์เดียว ใช้ workspace สลับ environment
```

```hcl
locals {
  # ← ใช้ชื่อ workspace เป็นชื่อ environment อัตโนมัติ
  environment_name = terraform.workspace  # "default", "staging", "production"
}

module "web_app" {
  source = "../../06-organization-and-modules/web-app-module"

  environment_name = local.environment_name
  # สร้าง DNS zone เฉพาะ production
  create_dns_zone  = terraform.workspace == "production" ? true : false
  db_name          = "${local.environment_name}mydb"
  # ... other variables ...
}
```

**วิธีใช้:**
```bash
# สร้าง workspace ใหม่
terraform workspace new staging
terraform workspace new production

# สลับ workspace
terraform workspace select staging
terraform apply  # ← apply สำหรับ staging

terraform workspace select production
terraform apply  # ← apply สำหรับ production

# ดู workspace ทั้งหมด
terraform workspace list
```

**ข้อดี:**
- ไฟล์เดียว ไม่ซ้ำ
- เหมาะกับ infrastructure ที่ทุก env เหมือนกันมากๆ

**ข้อเสีย:**
- State ทุก env อยู่ใน backend เดียวกัน
- ยากต่อการให้สิทธิ์แยก (RBAC)
- ลืมสลับ workspace → apply ผิด env

### สรุปเปรียบเทียบ

| หัวข้อ | File Structure | Workspaces |
|--------|---------------|------------|
| Code duplication | มาก | น้อย |
| State isolation | แยกชัดเจน | อยู่รวมกัน |
| ความปลอดภัย | ดีกว่า | ต่ำกว่า |
| ความยืดหยุ่น | สูง | ต่ำ |
| เหมาะกับ | Production จริง | ทดลอง/ส่วนตัว |

---

## 9. Lesson 08 - Testing Terraform

### สิ่งที่สอน
การทดสอบ Terraform code ตั้งแต่ static analysis จนถึง integration test

### ระดับของการทดสอบ

```
                    ↑ ความมั่นใจสูง แต่ช้าและแพง
                    │
    ┌───────────────┤
    │ Integration   │  Terratest (Go) - สร้างจริง ทดสอบจริง ลบทิ้ง
    │ Test          │
    ├───────────────┤
    │ Plan Test     │  terraform plan - ตรวจ diff ก่อน apply
    │               │
    ├───────────────┤
    │ Static        │  terraform validate, tflint, checkov, snyk
    │ Analysis      │
    ├───────────────┤
    │ Formatting    │  terraform fmt - ตรวจ coding style
    └───────────────┘
                    │
                    ↓ เร็ว ถูก แต่ความมั่นใจต่ำ
```

**1. Formatting:**
```bash
terraform fmt -check    # ตรวจว่า format ถูกต้องไหม
terraform fmt           # จัด format ให้อัตโนมัติ
```

**2. Validation:**
```bash
terraform validate  # ตรวจ syntax, type, required fields
```

**3. Static Analysis (เครื่องมือภายนอก):**
| เครื่องมือ | จุดเด่น |
|-----------|--------|
| tflint | ตรวจ best practices, ตรวจ resource-specific rules |
| checkov | ตรวจ security compliance (CIS benchmarks) |
| terrascan | ตรวจ security policies |
| snyk | ตรวจ vulnerabilities + license issues |
| Sentinel | Policy as Code สำหรับ Terraform Cloud/Enterprise |

**4. Terratest (Integration Test ด้วย Go):**
```go
// ตัวอย่าง Terratest
func TestWebApp(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/hello-world",
    }

    // สร้าง infrastructure จริง → ทดสอบ → ทำลาย
    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    // ดึง output มาทดสอบ
    instanceIP := terraform.Output(t, terraformOptions, "instance_ip_addr")

    // ทดสอบว่า HTTP server ตอบกลับถูกต้อง
    url := fmt.Sprintf("http://%s:8080", instanceIP)
    http_helper.HttpGetWithRetry(t, url, nil, 200, "Hello, World", 30, 5*time.Second)
}
```

---

## 10. Lesson 09 - Developer Workflows & CI/CD

### สิ่งที่สอน
การทำงานเป็นทีมกับ Terraform และ Automation

### GitHub Actions Workflow

```yaml
# .github/workflows/terraform.yml
name: "Terraform"

on:
  push:
    branches: [main]
  pull_request:

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v1

      - name: Terraform Format
        run: terraform fmt -check         # ← ตรวจ format

      - name: Terraform Init
        run: terraform init               # ← ดาวน์โหลด providers

      - name: Terraform Validate
        run: terraform validate           # ← ตรวจ syntax

      - name: Terraform Plan
        run: terraform plan               # ← ดู diff

      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve  # ← apply เฉพาะ main branch
```

### แนวทางการทำงานเป็นทีม
1. แต่ละคนทำงานใน feature branch
2. สร้าง PR → CI รัน `fmt`, `validate`, `plan`
3. ทีมรีวิว plan output
4. Merge เข้า main → CI รัน `apply`

---

## 11. Terragrunt คืออะไร และช่วย Terraform ได้อย่างไร

### Terragrunt คืออะไร?

Terragrunt เป็น **wrapper** ของ Terraform ที่สร้างโดย Gruntwork
ช่วยแก้ปัญหาที่ Terraform ทำเองไม่ได้ดีนัก เช่น:
- DRY (Don't Repeat Yourself) configuration
- การจัดการหลาย environment โดยไม่ต้อง copy-paste
- การ orchestrate หลาย module ให้ทำงานร่วมกัน
- การจัดการ backend configuration ที่ซ้ำกัน

---

### Terragrunt ช่วยแต่ละ Lesson ได้อย่างไร

### Lesson 03 - Backend Configuration

**ปัญหา:** ทุก module ต้อง copy-paste backend config เดิมๆ
```hcl
# ← ต้องเขียนซ้ำทุกไฟล์!
terraform {
  backend "s3" {
    bucket         = "devops-directive-tf-state"
    key            = "03-basics/web-app/terraform.tfstate"  # ← เปลี่ยนแค่ key
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }
}
```

**Terragrunt แก้ปัญหานี้ด้วย `generate` block:**
```hcl
# root terragrunt.hcl (เขียนครั้งเดียวที่ root)
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "devops-directive-tf-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    #                 ↑ สร้าง key อัตโนมัติจาก folder path!
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }
}
```

**ผลลัพธ์:**
```
infrastructure/
  ├── terragrunt.hcl           ← backend config เขียนครั้งเดียว
  ├── staging/
  │   └── terragrunt.hcl       ← key = "staging/terraform.tfstate" (auto!)
  └── production/
      └── terragrunt.hcl       ← key = "production/terraform.tfstate" (auto!)
```

---

### Lesson 04 - Variables & DRY Configuration

**ปัญหา:** ค่า common variables ซ้ำกันทุก env (region, ami, provider version)

**Terragrunt แก้ด้วย `inputs` inheritance:**
```hcl
# root terragrunt.hcl
inputs = {
  region        = "us-east-1"
  ami           = "ami-011899242bb902164"
  instance_type = "t2.micro"
}
```

```hcl
# staging/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()  # ← สืบทอด config จาก root
}

inputs = {
  # override เฉพาะค่าที่ต่างจาก root
  environment_name = "staging"
  instance_type    = "t2.micro"   # staging ใช้เครื่องเล็ก
}
```

```hcl
# production/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

inputs = {
  environment_name = "production"
  instance_type    = "t2.large"   # production ใช้เครื่องใหญ่
}
```

---

### Lesson 06 - Modules

**ปัญหา:** ต้อง copy `source = "../web-app-module"` ทุกที่

**Terragrunt แก้ด้วย `terraform` block:**
```hcl
# staging/web-app/terragrunt.hcl
terraform {
  source = "../../modules/web-app-module"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  environment_name = "staging"
  db_name          = "stagingmydb"
}
```

---

### Lesson 07 - Multiple Environments (แก้ปัญหาหลักที่สุด!)

**ปัญหาจาก File Structure approach:**
```
file-structure/
  ├── staging/
  │   └── main.tf       ← 47 บรรทัด (ซ้ำกับ production 90%)
  └── production/
      └── main.tf       ← 47 บรรทัด (ซ้ำกับ staging 90%)
```

**Terragrunt แก้ปัญหานี้อย่างสวยงาม:**

```
infrastructure-live/
  ├── terragrunt.hcl                    ← root config (backend + common inputs)
  │
  ├── _envcommon/
  │   └── web-app.hcl                   ← shared module config
  │
  ├── staging/
  │   ├── env.hcl                       ← environment-specific vars
  │   └── web-app/
  │       └── terragrunt.hcl            ← 10 บรรทัด! (แค่ include + override)
  │
  └── production/
      ├── env.hcl
      └── web-app/
          └── terragrunt.hcl            ← 10 บรรทัด!
```

**root terragrunt.hcl:**
```hcl
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "devops-directive-tf-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "us-east-1"
}
EOF
}
```

**_envcommon/web-app.hcl:**
```hcl
terraform {
  source = "${local.base_source_url}"
}

locals {
  base_source_url = "../../modules/web-app-module"
}

inputs = {
  domain          = "devopsdeployed.com"
  create_dns_zone = false
  db_user         = "foo"
}
```

**staging/env.hcl:**
```hcl
locals {
  environment_name = "staging"
  instance_type    = "t2.micro"
}
```

**staging/web-app/terragrunt.hcl:**
```hcl
include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/web-app.hcl"
  merge_strategy = "deep"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  environment_name = local.env_vars.locals.environment_name
  instance_type    = local.env_vars.locals.instance_type
  bucket_prefix    = "web-app-data-${local.env_vars.locals.environment_name}"
  db_name          = "${local.env_vars.locals.environment_name}mydb"
}
```

---

### Lesson 09 - Orchestration & Dependencies

**ปัญหา:** ต้อง `cd` ไปแต่ละ folder แล้ว `terraform apply` ทีละตัว ตามลำดับ

**Terragrunt แก้ด้วย `dependency` block + `run-all`:**
```hcl
# staging/web-app/terragrunt.hcl
dependency "vpc" {
  config_path = "../vpc"
}

dependency "database" {
  config_path = "../database"
}

inputs = {
  vpc_id = dependency.vpc.outputs.vpc_id
  db_url = dependency.database.outputs.connection_string
}
```

```bash
# apply ทุก module ตามลำดับ dependency อัตโนมัติ!
terragrunt run-all apply

# plan ทุก module
terragrunt run-all plan

# destroy ทั้งหมด (ลำดับย้อนกลับอัตโนมัติ)
terragrunt run-all destroy
```

---

### สรุป Terragrunt ช่วยอะไรบ้าง

| ปัญหาใน Terraform | Terragrunt แก้ด้วย |
|-------------------|-------------------|
| Backend config ซ้ำกัน | `remote_state` + `path_relative_to_include()` |
| Provider config ซ้ำกัน | `generate "provider"` |
| Variables ซ้ำกัน | `inputs` inheritance + `include` |
| Module source ซ้ำกัน | `terraform { source = "..." }` + `include` |
| Copy-paste ข้าม env | `_envcommon` + `env.hcl` pattern |
| Manual orchestration | `dependency` block + `run-all` |
| ไม่มี before/after hooks | `before_hook` / `after_hook` |

---

## 12. การสร้าง Web App Infrastructure ตั้งแต่เริ่มต้น

### สถานการณ์
ต้องการสร้าง Web Application ที่มี:
- Frontend/Backend server (EC2)
- Load Balancer (กระจาย traffic)
- Database (PostgreSQL)
- Storage (S3)
- DNS (ชื่อโดเมน)
- HTTPS (SSL/TLS)

### ลำดับการสร้าง (สำคัญมาก!)

```
ขั้นตอนที่ 1: Remote State Backend (S3 + DynamoDB)
     │         เหตุผล: ต้องมีที่เก็บ state ก่อนสร้าง resource อื่นๆ
     ▼
ขั้นตอนที่ 2: Networking (VPC + Subnets + Security Groups)
     │         เหตุผล: ทุก resource ต้องอยู่ใน network
     ▼
ขั้นตอนที่ 3: Database (RDS)
     │         เหตุผล: สร้างนานที่สุด (~10 นาที) + app ต้องรู้ endpoint
     ▼
ขั้นตอนที่ 4: Storage (S3)
     │         เหตุผล: app อาจต้องใช้เก็บไฟล์
     ▼
ขั้นตอนที่ 5: Compute (EC2 instances)
     │         เหตุผล: ต้องรู้ DB endpoint + S3 bucket name ก่อน
     ▼
ขั้นตอนที่ 6: Load Balancer (ALB)
     │         เหตุผล: ต้องมี EC2 ก่อนถึงจะผูกเข้า target group ได้
     ▼
ขั้นตอนที่ 7: DNS (Route53)
     │         เหตุผล: ต้องมี ALB ก่อนถึงจะชี้ DNS ไปได้
     ▼
ขั้นตอนที่ 8: HTTPS (ACM + Listener)
               เหตุผล: ต้องมี DNS ก่อนถึงจะ validate SSL certificate ได้
```

> **หมายเหตุ:** Terraform จัดการ dependency อัตโนมัติผ่าน resource references
> แต่การเข้าใจลำดับนี้ช่วยให้ debug ได้ง่ายขึ้น

---

### ขั้นตอนที่ 1: Remote State Backend

**เหตุผล:** State file คือ "สมอง" ของ Terraform - ถ้าหาย ทุกอย่างพัง

```hcl
###############################################################################
# ไฟล์: 01-backend/main.tf
# เป้าหมาย: สร้างที่เก็บ state file บน S3 + DynamoDB สำหรับ locking
###############################################################################

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

# S3 Bucket - เก็บ state file
# เหตุผลที่ใช้ S3: ทนทาน (99.999999999% durability), เข้ารหัสได้, versioning ได้
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-company-terraform-state"   # เปลี่ยนให้ไม่ซ้ำ

  # ⚠️ ใน production จริง ควรตั้ง force_destroy = false
  # เพราะถ้า state file หายไป จะไม่สามารถจัดการ infrastructure ได้
  force_destroy = true

  tags = {
    Name        = "Terraform State"
    ManagedBy   = "terraform"
  }
}

# เปิด Versioning - เก็บ state file ทุก version
# เหตุผล: ถ้า state file เสียหาย สามารถย้อนกลับ version เก่าได้
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# เข้ารหัส state file
# เหตุผล: state file มี sensitive data เช่น DB password, API keys
resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.terraform_state.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ปิด public access ของ S3 bucket
# เหตุผล: state file ไม่ควรเข้าถึงได้จากภายนอก
resource "aws_s3_bucket_public_access_block" "state_public_access" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB Table - State Locking
# เหตุผล: ป้องกัน 2 คนรัน terraform apply พร้อมกัน ซึ่งจะทำให้ state เสียหาย
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"  # จ่ายตามใช้งาน (ประหยัดกว่า provisioned)
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
```

**วิธี apply:**
```bash
# ครั้งแรก: ใช้ local backend
terraform init
terraform apply

# หลังสร้าง S3 + DynamoDB แล้ว: เพิ่ม backend config แล้ว init ใหม่
terraform init  # → จะถามว่าจะย้าย state ไป S3 ไหม → yes
```

---

### ขั้นตอนที่ 2: Networking

**เหตุผล:** ทุก resource (EC2, RDS, ALB) ต้องอยู่ใน network — ถ้าไม่มี VPC/Subnet จะสร้างอะไรไม่ได้

```hcl
###############################################################################
# ไฟล์: modules/networking/main.tf
# เป้าหมาย: สร้าง VPC, Subnets, Security Groups
###############################################################################

# ดึง Availability Zones ที่มีใน region
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC - Virtual Private Cloud (เครือข่ายส่วนตัวบน AWS)
# เหตุผล: แยก network ของเราออกจากคนอื่น + ควบคุม traffic ได้
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr  # เช่น "10.0.0.0/16" (65,536 IPs)
  enable_dns_support   = true          # เปิด DNS resolution ภายใน VPC
  enable_dns_hostnames = true          # EC2 ได้รับ public DNS hostname

  tags = {
    Name = "${var.app_name}-${var.environment}-vpc"
  }
}

# Public Subnets - สำหรับ ALB และ EC2 ที่ต้องเข้าถึงจาก internet
# เหตุผล: ALB ต้องอยู่ใน public subnet อย่างน้อย 2 AZ
resource "aws_subnet" "public" {
  count                   = 2  # สร้าง 2 subnets ใน 2 AZ
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  # cidrsubnet("10.0.0.0/16", 8, 0) → "10.0.0.0/24"
  # cidrsubnet("10.0.0.0/16", 8, 1) → "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true  # EC2 ใน subnet นี้จะได้รับ public IP อัตโนมัติ

  tags = {
    Name = "${var.app_name}-${var.environment}-public-${count.index}"
  }
}

# Private Subnets - สำหรับ RDS (database ไม่ควรเข้าถึงจาก internet)
# เหตุผล: database ควรอยู่ใน private subnet เพื่อความปลอดภัย
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  # cidrsubnet("10.0.0.0/16", 8, 10) → "10.0.10.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.app_name}-${var.environment}-private-${count.index}"
  }
}

# Internet Gateway - ให้ public subnet เข้าถึง internet ได้
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.app_name}-${var.environment}-igw"
  }
}

# Route Table - กำหนดเส้นทาง traffic
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"  # traffic ทุก destination
    gateway_id = aws_internet_gateway.main.id  # ส่งออก internet gateway
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-public-rt"
  }
}

# ผูก Route Table กับ Public Subnets
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Group สำหรับ EC2 instances
resource "aws_security_group" "instances" {
  name   = "${var.app_name}-${var.environment}-instance-sg"
  vpc_id = aws_vpc.main.id

  # อนุญาต traffic จาก ALB เท่านั้น (ไม่เปิดให้ทุกคน)
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]  # ← เฉพาะจาก ALB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group สำหรับ ALB
resource "aws_security_group" "alb" {
  name   = "${var.app_name}-${var.environment}-alb-sg"
  vpc_id = aws_vpc.main.id

  # เปิด port 80 (HTTP) จากทุกที่
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # เปิด port 443 (HTTPS) จากทุกที่
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group สำหรับ RDS
resource "aws_security_group" "database" {
  name   = "${var.app_name}-${var.environment}-db-sg"
  vpc_id = aws_vpc.main.id

  # อนุญาตเฉพาะ traffic จาก EC2 instances
  ingress {
    from_port       = 5432        # PostgreSQL port
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.instances.id]  # ← เฉพาะจาก EC2
  }
}
```

---

### ขั้นตอนที่ 3: Database (RDS)

**เหตุผลที่สร้างก่อน EC2:**
- RDS ใช้เวลาสร้างนาน (~10-15 นาที)
- EC2 (application) ต้องรู้ DB endpoint เพื่อ connect

```hcl
###############################################################################
# ไฟล์: modules/database/main.tf
# เป้าหมาย: สร้าง RDS PostgreSQL
###############################################################################

# DB Subnet Group - กำหนดว่า RDS จะอยู่ใน subnets ไหน
# เหตุผล: RDS ต้องการ subnet อย่างน้อย 2 AZ สำหรับ Multi-AZ failover
resource "aws_db_subnet_group" "main" {
  name       = "${var.app_name}-${var.environment}-db-subnet"
  subnet_ids = var.private_subnet_ids  # ← ใช้ private subnet (ปลอดภัยกว่า)

  tags = {
    Name = "${var.app_name}-${var.environment}-db-subnet"
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.app_name}-${var.environment}-db"

  # Engine
  engine         = "postgres"
  engine_version = "15"             # ใช้ version ที่ stable

  # Sizing
  instance_class    = var.db_instance_class  # "db.t3.micro" สำหรับ dev
  allocated_storage = 20                     # GB
  storage_type      = "gp3"                 # SSD (เร็วกว่า standard)

  # Database
  db_name  = var.db_name
  username = var.db_user
  password = var.db_pass  # ⚠️ ควรใช้ AWS Secrets Manager ใน production

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_security_group_id]

  # ไม่ให้เข้าถึงจาก internet
  publicly_accessible = false

  # Backup
  backup_retention_period = var.environment == "production" ? 7 : 1
  # production: เก็บ backup 7 วัน / dev: เก็บ 1 วัน

  # ข้าม final snapshot เมื่อลบ (dev เท่านั้น)
  skip_final_snapshot = var.environment == "production" ? false : true

  tags = {
    Name        = "${var.app_name}-${var.environment}-db"
    Environment = var.environment
  }
}
```

---

### ขั้นตอนที่ 4: Storage (S3)

**เหตุผล:** Application อาจต้องเก็บไฟล์ (user uploads, logs, assets)

```hcl
###############################################################################
# ไฟล์: modules/storage/main.tf
# เป้าหมาย: สร้าง S3 bucket สำหรับ application data
###############################################################################

resource "aws_s3_bucket" "app_data" {
  bucket_prefix = "${var.app_name}-${var.environment}-data"
  force_destroy = var.environment == "production" ? false : true
  # production: ไม่ให้ลบ bucket ถ้ายังมีไฟล์ (ป้องกันข้อมูลหาย)
  # dev: ลบได้เลย (สะดวกตอน destroy)

  tags = {
    Name        = "${var.app_name}-${var.environment}-data"
    Environment = var.environment
  }
}

# Versioning
resource "aws_s3_bucket_versioning" "app_data" {
  bucket = aws_s3_bucket.app_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "app_data" {
  bucket = aws_s3_bucket.app_data.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ปิด public access
resource "aws_s3_bucket_public_access_block" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

---

### ขั้นตอนที่ 5: Compute (EC2)

**เหตุผลที่สร้างหลัง DB & S3:** Application ต้องรู้ DB endpoint และ S3 bucket name

```hcl
###############################################################################
# ไฟล์: modules/compute/main.tf
# เป้าหมาย: สร้าง EC2 instances สำหรับรัน web application
###############################################################################

# ดึง AMI Ubuntu ล่าสุด
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instance 1
resource "aws_instance" "app_1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_ids[0]     # วางใน AZ แรก
  vpc_security_group_ids = [var.instance_security_group_id]

  # user_data: script ที่รันตอน instance เริ่มทำงานครั้งแรก
  user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World 1" > index.html
    python3 -m http.server 8080 &
  EOF

  tags = {
    Name = "${var.app_name}-${var.environment}-instance-1"
  }
}

# EC2 Instance 2
resource "aws_instance" "app_2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_ids[1]     # วางใน AZ ที่สอง (High Availability)
  vpc_security_group_ids = [var.instance_security_group_id]

  user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World 2" > index.html
    python3 -m http.server 8080 &
  EOF

  tags = {
    Name = "${var.app_name}-${var.environment}-instance-2"
  }
}
```

---

### ขั้นตอนที่ 6: Load Balancer (ALB)

**เหตุผล:**
- กระจาย traffic ไป EC2 หลายตัว (High Availability)
- ถ้า EC2 ตัวใดตัวหนึ่งพัง ALB จะหยุดส่ง traffic ไปหามัน
- เป็นจุดเดียวที่รับ traffic จากภายนอก (single entry point)

```hcl
###############################################################################
# ไฟล์: modules/loadbalancer/main.tf
# เป้าหมาย: สร้าง ALB เพื่อกระจาย traffic ไปยัง EC2 instances
###############################################################################

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.app_name}-${var.environment}-alb"
  load_balancer_type = "application"    # Layer 7 (HTTP/HTTPS)
  subnets            = var.public_subnet_ids
  security_groups    = [var.alb_security_group_id]
  internal           = false            # internet-facing (เข้าถึงจากภายนอกได้)

  tags = {
    Name = "${var.app_name}-${var.environment}-alb"
  }
}

# Target Group - กลุ่ม EC2 ที่ ALB จะส่ง traffic ไปให้
resource "aws_lb_target_group" "app" {
  name     = "${var.app_name}-${var.environment}-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  # Health Check - ตรวจว่า EC2 ยังทำงานปกติ
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15    # ตรวจทุก 15 วินาที
    timeout             = 3     # timeout 3 วินาที
    healthy_threshold   = 2     # ผ่าน 2 ครั้ง → healthy
    unhealthy_threshold = 2     # ไม่ผ่าน 2 ครั้ง → unhealthy (หยุดส่ง traffic)
  }
}

# ผูก EC2 instance 1 เข้ากับ target group
resource "aws_lb_target_group_attachment" "app_1" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = var.instance_1_id
  port             = 8080
}

# ผูก EC2 instance 2 เข้ากับ target group
resource "aws_lb_target_group_attachment" "app_2" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = var.instance_2_id
  port             = 8080
}

# HTTP Listener - รับ traffic port 80
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # Default: redirect HTTP → HTTPS (best practice)
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"   # Permanent redirect
    }
  }
}

# HTTPS Listener - รับ traffic port 443
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn  # SSL certificate จาก ACM

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
```

---

### ขั้นตอนที่ 7: DNS (Route53)

**เหตุผล:** ให้ user เข้าเว็บผ่านชื่อโดเมนแทน ALB DNS ที่ยาวและจำยาก

```hcl
###############################################################################
# ไฟล์: modules/dns/main.tf
# เป้าหมาย: สร้าง DNS records ชี้โดเมนไปยัง ALB
###############################################################################

# สร้าง Hosted Zone (ถ้ายังไม่มี)
resource "aws_route53_zone" "main" {
  count = var.create_dns_zone ? 1 : 0
  name  = var.domain
}

# ดึง Hosted Zone ที่มีอยู่แล้ว (ถ้ามี)
data "aws_route53_zone" "existing" {
  count = var.create_dns_zone ? 0 : 1
  name  = var.domain
}

locals {
  zone_id = var.create_dns_zone ? aws_route53_zone.main[0].zone_id : data.aws_route53_zone.existing[0].zone_id
  # production → "example.com" / staging → "staging.example.com"
  subdomain = var.environment == "production" ? "" : "${var.environment}."
}

# A Record (Alias) - ชี้โดเมนไปที่ ALB
resource "aws_route53_record" "app" {
  zone_id = local.zone_id
  name    = "${local.subdomain}${var.domain}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true  # ตรวจ health ก่อน resolve
  }
}
```

---

### ขั้นตอนที่ 8: HTTPS (ACM)

**เหตุผล:**
- เข้ารหัส traffic ระหว่าง user กับ server
- Google ให้คะแนน SEO ดีกว่าสำหรับ HTTPS
- Browser แสดง "Not Secure" ถ้าไม่มี HTTPS

```hcl
###############################################################################
# ไฟล์: modules/certificate/main.tf
# เป้าหมาย: สร้าง SSL/TLS certificate ด้วย AWS Certificate Manager
###############################################################################

# สร้าง SSL Certificate (ฟรี! จาก AWS)
resource "aws_acm_certificate" "main" {
  domain_name       = var.domain                  # เช่น "example.com"
  subject_alternative_names = ["*.${var.domain}"]  # wildcard สำหรับ subdomain ทั้งหมด
  validation_method = "DNS"                        # validate ผ่าน DNS record

  lifecycle {
    create_before_destroy = true
    # สร้าง cert ใหม่ก่อน แล้วค่อยลบอันเก่า → ไม่มี downtime
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-cert"
  }
}

# สร้าง DNS record เพื่อ validate certificate
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# รอให้ certificate ถูก validate สำเร็จ
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
```

---

### โครงสร้าง Project ที่แนะนำ (รวมทั้งหมด)

```
my-web-app-infrastructure/
│
├── terragrunt.hcl                      ← Root: backend + provider config
│
├── modules/                            ← Reusable Terraform modules
│   ├── networking/
│   │   ├── main.tf                     ← VPC, Subnets, Security Groups
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── database/
│   │   ├── main.tf                     ← RDS PostgreSQL
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── storage/
│   │   ├── main.tf                     ← S3 Bucket
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/
│   │   ├── main.tf                     ← EC2 Instances
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── loadbalancer/
│   │   ├── main.tf                     ← ALB + Target Groups
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── dns/
│   │   ├── main.tf                     ← Route53
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── certificate/
│       ├── main.tf                     ← ACM SSL Certificate
│       ├── variables.tf
│       └── outputs.tf
│
├── environments/
│   ├── _envcommon/                     ← Shared Terragrunt configs
│   │   └── web-app.hcl
│   │
│   ├── staging/
│   │   ├── env.hcl                     ← environment = "staging"
│   │   ├── networking/
│   │   │   └── terragrunt.hcl
│   │   ├── database/
│   │   │   └── terragrunt.hcl
│   │   ├── compute/
│   │   │   └── terragrunt.hcl
│   │   └── loadbalancer/
│   │       └── terragrunt.hcl
│   │
│   └── production/
│       ├── env.hcl                     ← environment = "production"
│       ├── networking/
│       │   └── terragrunt.hcl
│       ├── database/
│       │   └── terragrunt.hcl
│       ├── compute/
│       │   └── terragrunt.hcl
│       └── loadbalancer/
│           └── terragrunt.hcl
│
└── README.md
```

---

### Deploy ทั้งหมดด้วย Terragrunt

```bash
# Deploy staging ทั้งหมด (Terragrunt จัดการลำดับ dependency ให้)
cd environments/staging
terragrunt run-all apply

# Deploy เฉพาะ database
cd environments/staging/database
terragrunt apply

# Destroy staging ทั้งหมด
cd environments/staging
terragrunt run-all destroy

# Plan ทุก module
terragrunt run-all plan
```

---

### สรุป: ลำดับการสร้างและเหตุผล

| ลำดับ | Resource | เหตุผลที่ต้องสร้างก่อน/หลัง |
|-------|----------|---------------------------|
| 1 | **S3 + DynamoDB** (Backend) | ต้องมีก่อนทุกอย่าง เพราะเก็บ state file |
| 2 | **VPC + Subnets + SG** (Networking) | ทุก resource ต้องอยู่ใน network |
| 3 | **RDS** (Database) | ใช้เวลาสร้างนาน + app ต้องรู้ endpoint |
| 4 | **S3** (Storage) | app อาจต้องรู้ bucket name |
| 5 | **EC2** (Compute) | ต้องรู้ DB endpoint + S3 name + อยู่ใน subnet |
| 6 | **ALB** (Load Balancer) | ต้องมี EC2 ก่อนถึงจะผูก target group |
| 7 | **Route53** (DNS) | ต้องมี ALB ก่อนถึงจะชี้ DNS ไป |
| 8 | **ACM** (HTTPS) | ต้องมี DNS ก่อนถึงจะ validate certificate |

---

### Terraform Commands Cheat Sheet

```bash
# พื้นฐาน
terraform init        # ดาวน์โหลด providers + initialize backend
terraform plan        # ดู diff (dry-run)
terraform apply       # สร้าง/แก้ไข resource
terraform destroy     # ลบ resource ทั้งหมด

# ตรวจสอบ
terraform fmt         # จัด format โค้ด
terraform validate    # ตรวจ syntax
terraform state list  # ดู resource ทั้งหมดใน state

# Debug
terraform console     # เปิด interactive console (ทดสอบ expressions)
terraform output      # ดู output values
terraform show        # ดู state ปัจจุบัน

# Terragrunt
terragrunt run-all plan     # plan ทุก module
terragrunt run-all apply    # apply ทุก module ตามลำดับ dependency
terragrunt run-all destroy  # destroy ทุก module (ลำดับย้อนกลับ)
terragrunt graph-dependencies  # แสดง dependency graph
```
