# ==============================================================================
# Outputs - ค่าที่แสดงหลัง terraform apply
# ==============================================================================

# ── EC2: Swarm Nodes ─────────────────────────────────────────────────────────

output "manager_public_ip" {
  description = "Public IP ของ Swarm Manager (ใช้เปิด Portainer + Traefik)"
  value       = aws_instance.manager.public_ip
}

output "worker_public_ips" {
  description = "Public IPs ของ Swarm Workers"
  value       = aws_instance.worker[*].public_ip
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

# ── Ansible Inventory ────────────────────────────────────────────────────────
# output นี้สร้าง inventory ให้ Ansible ใช้ได้เลย

output "ansible_inventory" {
  description = "Ansible inventory content (copy ไปใส่ ansible/inventory.ini)"
  value = <<-EOT

    [manager]
    ${aws_instance.manager.public_ip}

    [workers]
    ${join("\n    ", aws_instance.worker[*].public_ip)}

    [swarm:children]
    manager
    workers

  EOT
}
