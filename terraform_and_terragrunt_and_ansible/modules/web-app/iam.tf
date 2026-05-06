# ==============================================================================
# IAM Role สำหรับ EC2 - เพื่อให้ EC2 สามารถอ่าน ECR ได้
# ==============================================================================

# ── IAM Role ────────────────────────────────────────────────────────────────
resource "aws_iam_role" "ec2_ecr_access" {
  name = "${var.app_name}-${var.environment}-ec2-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.app_name}-${var.environment}-ec2-ecr-role"
  }
}

# ── IAM Policy - อนุญาตให้ EC2 อ่าน ECR ──────────────────────────────────
resource "aws_iam_role_policy" "ecr_access" {
  name = "${var.app_name}-${var.environment}-ecr-access-policy"
  role = aws_iam_role.ec2_ecr_access.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken",
          "ecr:DescribeImages",
          "ecr:ListImages"
        ]
        Resource = "*"
      }
    ]
  })
}

# ── IAM Instance Profile ────────────────────────────────────────────────────
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.app_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_ecr_access.id
}
