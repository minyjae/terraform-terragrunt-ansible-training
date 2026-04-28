# ==============================================================================
# Database - RDS PostgreSQL
# ==============================================================================

resource "aws_db_instance" "main" {
  allocated_storage          = 20
  auto_minor_version_upgrade = true
  storage_type               = "gp2"
  engine                     = "postgres"
  engine_version             = "15"
  instance_class             = "db.t3.micro"
  db_name                    = var.db_name
  username                   = var.db_user
  password                   = var.db_pass
  skip_final_snapshot        = true

  tags = {
    Name = "${var.app_name}-${var.environment}-db"
  }
}
