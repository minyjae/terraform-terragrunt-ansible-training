# ==============================================================================
# Develop Environment Variables
# ค่าเฉพาะสำหรับ develop environment
# ==============================================================================

locals {
  environment   = "develop"
  instance_type = "t2.micro"   # develop ใช้เครื่องเล็ก ประหยัดค่าใช้จ่าย
  app_name      = "web-app"
}
