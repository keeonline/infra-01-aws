resource "aws_security_group" "alb" {
  name        = "${var.infra_environment}-sg-alb"
  description = "ALB security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.infra_environment}-sg-alb"
    Created = "${timestamp()}"
    # Environment = "${var.infra_environment}"
    # Category    = "${var.resource_category}"
    # Version     = "${var.infra_version}"
  }
}

# Add ALB INGRESS rule so it can receive HTTP trafic over port 18080 from the internet
resource "aws_vpc_security_group_ingress_rule" "alb_ingress_services" {
  security_group_id = aws_security_group.alb.id
  description       = "Ingress rule to allow inbound HTTP traffic to the service ALB"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 18080
  ip_protocol       = "tcp"
  to_port           = 18080

  tags = {
    Name = "${var.infra_environment}-sg-rule-alb-public-http-ingress"
    # Environment = "${var.infra_environment}"
    # Category    = "${var.resource_category}"
    # Version     = "${var.infra_version}"
  }
}

# Add ALB EGRESS rules to existing ALB so that it can talk to services in the private subnet
resource "aws_vpc_security_group_egress_rule" "alb_egress_services" {
  count             = length(aws_subnet.private)
  description       = "Egress rule to allow outbound consumer request traffic to the services in the private subnet"
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = aws_subnet.private[count.index].cidr_block
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"

  tags = {
    Name = "${var.infra_environment}-sg-alb-egress-services-${count.index}"
    # Environment = "${var.infra_environment}"
  }
}

resource "aws_vpc_security_group_egress_rule" "alb_egress_management" {
  count             = length(aws_subnet.private)
  description       = "Egress rule to allow outbound healthcheck traffic to the services in the private subnet"
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = aws_subnet.private[count.index].cidr_block
  from_port         = 9080
  to_port           = 9080
  ip_protocol       = "tcp"

  tags = {
    Name = "${var.infra_environment}-sg-alb-egress-management-${count.index}"
    # Environment = "${var.infra_environment}"
  }
}



resource "aws_lb" "alb" {
  name               = "${var.infra_environment}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [for subnet in aws_subnet.public : subnet.id]
  security_groups    = [aws_security_group.alb.id]

  tags = {
    Name = "${var.infra_environment}-alb"
    # Environment = "${var.infra_environment}"
    # Category    = "${var.resource_category}"
    # Version     = "${var.infra_version}"
  }
}

resource "aws_lb_listener" "api_requests" {
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
    Name = "${var.infra_environment}-alb-listener-api-requests"
    # Environment = "${var.infra_environment}"
    # Category    = "${var.resource_category}"
    # Version     = "${var.infra_version}"
  }
}
