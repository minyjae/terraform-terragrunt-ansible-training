# ==============================================================================
# Outputs - ค่าที่แสดงหลัง terraform apply
# ==============================================================================

# ── EC2 ───────────────────────────────────────────────────────────────────────

output "instance_1_public_ip" {
  description = "Public IP ของ EC2 instance 1"
  value       = aws_instance.instance_1.public_ip
}

output "instance_2_public_ip" {
  description = "Public IP ของ EC2 instance 2"
  value       = aws_instance.instance_2.public_ip
}

# ── ALB ───────────────────────────────────────────────────────────────────────

output "alb_dns_name" {
  description = "DNS name ของ ALB (ใช้เปิดเว็บแทน domain)"
  value       = aws_lb.main.dns_name
}

# ── S3 ────────────────────────────────────────────────────────────────────────

output "s3_bucket_name" {
  description = "ชื่อ S3 bucket ที่สร้าง"
  value       = aws_s3_bucket.app_data.bucket
}

# ── RDS ───────────────────────────────────────────────────────────────────────

output "db_endpoint" {
  description = "Endpoint สำหรับ connect ไปยัง database"
  value       = aws_db_instance.main.endpoint
}
