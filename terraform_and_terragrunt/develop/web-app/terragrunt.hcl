# ==============================================================================
# Develop - Web App
# เรียกใช้ module web-app โดย include config กลางจาก root + _envcommon
# แล้ว override เฉพาะค่าที่ develop ต้องการ
# ==============================================================================

# include root terragrunt.hcl (ได้ backend + provider มาอัตโนมัติ)
include "root" {
  path = find_in_parent_folders()
}

# include config ที่ทุก env ใช้ร่วมกัน (ได้ module source + ami + db_user)
include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/web-app.hcl"
  merge_strategy = "deep"
}

# อ่านค่าจาก env.hcl ของ develop
locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

# ค่าเฉพาะสำหรับ develop environment
inputs = {
  environment   = local.env.locals.environment      # "develop"
  app_name      = local.env.locals.app_name         # "web-app"
  instance_type = local.env.locals.instance_type    # "t2.micro"
  bucket_prefix = "web-app-data-${local.env.locals.environment}"  # "web-app-data-develop"
  db_name       = "${local.env.locals.environment}db"             # "developdb"
  db_pass       = "changeme123"  # develop ใส่ตรงได้ / production ควรใช้ sops หรือ env var
}
