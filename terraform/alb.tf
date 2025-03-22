resource "aws_security_group" "alb" {
  name        = "${var.environment}-sg-alb"
  description = "ALB security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-sg-alb"
    Environment = "${var.environment}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_ingress_services" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 18080
  ip_protocol       = "tcp"
  to_port           = 18080

  tags = {
    Name = "${var.environment}-sg-alb-ingress-services"
    Environment = "${var.environment}"
  }
}

resource "aws_vpc_security_group_egress_rule" "alb_egress_services" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"

  tags = {
    Name = "${var.environment}-sg-alb-egress-services"
    Environment = "${var.environment}"
  }
}

resource "aws_vpc_security_group_egress_rule" "alb_egress_management" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 9080
  to_port           = 9080
  ip_protocol       = "tcp"

  tags = {
    Name = "${var.environment}-sg-alb-egress-management"
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

resource "aws_lb_listener" "http" {
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
