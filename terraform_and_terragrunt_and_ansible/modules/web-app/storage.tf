# ==============================================================================
# Storage - S3 Bucket สำหรับเก็บข้อมูล application
# ==============================================================================

resource "aws_s3_bucket" "app_data" {
  bucket_prefix = "${var.bucket_prefix}-"
  force_destroy = true

  tags = {
    Name = "${var.app_name}-${var.environment}-data"
  }
}

resource "aws_s3_bucket_versioning" "app_data" {
  bucket = aws_s3_bucket.app_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_data" {
  bucket = aws_s3_bucket.app_data.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
