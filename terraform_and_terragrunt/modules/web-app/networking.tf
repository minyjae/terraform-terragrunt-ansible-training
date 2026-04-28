# ==============================================================================
# Networking - VPC data, Security Groups, ALB, Target Group
# ==============================================================================

# ── ดึงข้อมูล Default VPC & Subnets ────────────────────────────────────────

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ── Security Group: EC2 Instances ──────────────────────────────────────────

resource "aws_security_group" "instances" {
  name   = "${var.app_name}-${var.environment}-instances"
  vpc_id = data.aws_vpc.default.id
}

# เปิด port 8080 ให้ EC2 รับ traffic จาก ALB
resource "aws_security_group_rule" "instances_inbound_http" {
  type              = "ingress"
  security_group_id = aws_security_group.instances.id
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# ── Security Group: ALB ───────────────────────────────────────────────────

resource "aws_security_group" "alb" {
  name   = "${var.app_name}-${var.environment}-alb"
  vpc_id = data.aws_vpc.default.id
}

# ALB รับ traffic ขาเข้า port 80 (HTTP)
resource "aws_security_group_rule" "alb_inbound_http" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# ALB ส่ง traffic ออกได้ทุก port (ไปหา EC2 port 8080)
resource "aws_security_group_rule" "alb_outbound_all" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# ── Application Load Balancer ──────────────────────────────────────────────

resource "aws_lb" "main" {
  name               = "${var.app_name}-${var.environment}-alb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]

  tags = {
    Name = "${var.app_name}-${var.environment}-alb"
  }
}

# ── Target Group - กลุ่มเป้าหมายที่ ALB จะส่ง traffic ไปให้ ────────────

resource "aws_lb_target_group" "instances" {
  name     = "${var.app_name}-${var.environment}-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# ผูก EC2 ทั้ง 2 ตัวเข้ากับ Target Group
resource "aws_lb_target_group_attachment" "instance_1" {
  target_group_arn = aws_lb_target_group.instances.arn
  target_id        = aws_instance.instance_1.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "instance_2" {
  target_group_arn = aws_lb_target_group.instances.arn
  target_id        = aws_instance.instance_2.id
  port             = 8080
}

# ── Listener - รับ traffic port 80 แล้ว forward ไป Target Group ───────

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_listener_rule" "forward_to_instances" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.instances.arn
  }
}
