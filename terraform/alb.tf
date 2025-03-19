resource "aws_security_group" "alb" {
  name        = "${var.environment}-sg-alb"
  description = "ALB security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-sg-alb"
    Environment = "${var.environment}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 18080
  ip_protocol       = "tcp"
  to_port           = 18080

  tags = {
    Name = "${var.environment}-sg-alb"
    Environment = "${var.environment}"
  }
}

resource "aws_lb" "alb" {
  name = "${var.environment}-alb"
  internal = false
  load_balancer_type = "application"
  subnets = [for subnet in aws_subnet.public : subnet.id]
  security_groups = [aws_security_group.alb.id]

  tags = {
    Name = "${var.environment}-alb"
    Environment = "${var.environment}"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "18080"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "The service you have requested is unavailable"
      status_code  = "503"
    }
  }

  tags = {
    Name = "${var.environment}-alb-listener"
    Environment = "${var.environment}"
  }
}
