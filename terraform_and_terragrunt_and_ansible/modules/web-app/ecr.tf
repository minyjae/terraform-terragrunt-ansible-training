# ==============================================================================
# ECR Repository - เก็บ Docker image สำหรับ web app
# ==============================================================================

# ── ECR Repository ──────────────────────────────────────────────────────────
resource "aws_ecr_repository" "webapp" {
  name                 = "${var.app_name}-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-ecr"
  }
}

# ── Output: ECR Repository URL ──────────────────────────────────────────────
output "ecr_repository_url" {
  value       = aws_ecr_repository.webapp.repository_url
  description = "URL ของ ECR repository สำหรับ push/pull image"
}

output "ecr_repository_arn" {
  value       = aws_ecr_repository.webapp.arn
  description = "ARN ของ ECR repository"
}
