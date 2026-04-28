###############################################################################
# Shared Web App Configuration (Environment Common)
# ไฟล์นี้เก็บ config ที่ทุก environment (staging/production) ใช้เหมือนกัน
# เช่น: module source, domain, db_user
# ค่าที่ต่างกันระหว่าง env จะ override ใน staging/ หรือ production/
###############################################################################

# ──────────────────────────────────────────────────────────────────────────────
# Terraform Source - กำหนดว่าจะใช้ module จากที่ไหน
# ──────────────────────────────────────────────────────────────────────────────
terraform {
  # ชี้ไปที่ web-app module ของเราเอง (อยู่ใน modules/web-app)
  source = "${dirname(find_in_parent_folders())}/modules/web-app"
}

# ──────────────────────────────────────────────────────────────────────────────
# Common Inputs - ค่า variables ที่ทุก environment ใช้เหมือนกัน
# ──────────────────────────────────────────────────────────────────────────────
# ค่าเหล่านี้จะถูกส่งเป็น input variables ให้กับ Terraform module
# ถ้า staging/production ต้องการค่าต่างออกไป สามารถ override ได้ในไฟล์ของแต่ละ env
inputs = {
  # Domain ที่ใช้ร่วมกันทุก environment
  # (staging จะได้ staging.devopsdeployed.com, production จะได้ devopsdeployed.com)
  # domain = "devopsdeployed.com"

  # ไม่ต้องสร้าง DNS zone ใหม่ (ใช้ zone ที่มีอยู่แล้ว)
  # create_dns_zone = false

  # Database username ที่ใช้ร่วมกัน
  db_user = "foo"

  # AMI สำหรับ EC2 instances (Ubuntu 22.04 / ap-southeast-1)
  ami = "ami-011899242bb902164"

  # SSH Key Pair สำหรับ SSH เข้า EC2 (Ansible ใช้ SSH ในการติดตั้ง Docker + Swarm)
  # ← เปลี่ยนเป็นชื่อ key pair ที่สร้างไว้ใน AWS Console
  key_name = "my-key-pair"
}
