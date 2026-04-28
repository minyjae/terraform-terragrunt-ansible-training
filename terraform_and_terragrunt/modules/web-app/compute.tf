# ==============================================================================
# Compute - EC2 Instances
# สร้าง EC2 2 ตัว รัน web server คนละ AZ เพื่อ High Availability
# ==============================================================================

resource "aws_instance" "instance_1" {
  ami                    = var.ami
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.instances.id]

  # script ที่รันตอน instance boot ครั้งแรก
  # สร้าง web server ง่ายๆ ด้วย Python บน port 8080
  user_data = <<-EOF
    #!/bin/bash
    echo "Hello from ${var.app_name} - ${var.environment} - instance 1" > index.html
    python3 -m http.server 8080 &
  EOF

  tags = {
    Name = "${var.app_name}-${var.environment}-1"
  }
}

resource "aws_instance" "instance_2" {
  ami                    = var.ami
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.instances.id]

  user_data = <<-EOF
    #!/bin/bash
    echo "Hello from ${var.app_name} - ${var.environment} - instance 2" > index.html
    python3 -m http.server 8080 &
  EOF

  tags = {
    Name = "${var.app_name}-${var.environment}-2"
  }
}
