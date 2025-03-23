data "aws_lb" "alb" {
  name = "${var.environment}-alb"
}

data "aws_subnets" "public" {
  filter {
    name   = "tag:Environment"
    values = ["${var.environment}"]
  }

  filter {
    name   = "tag:Public"
    values = ["yes"]
  }

  depends_on = [data.aws_lb.alb]
}

data "aws_subnet" "public" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}

data "aws_subnets" "private" {
  filter {
    name   = "tag:Environment"
    values = ["${var.environment}"]
  }

  filter {
    name   = "tag:Public"
    values = ["no"]
  }

  depends_on = [data.aws_lb.alb]
}

data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

locals {
  public_subnet_cidr_blocks = [for s in data.aws_subnet.public : s.cidr_block]
  private_subnet_cidr_blocks = [for s in data.aws_subnet.private : s.cidr_block]
}

# Create a security group for use by services that allow traffic ingress and access to the NAT gateway

resource "aws_security_group" "service" {
  name        = "${var.environment}-sg-service"
  description = "Security group for ECS service running on Fargate"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-sg-service"
  }
}

resource "aws_vpc_security_group_ingress_rule" "service_traffic" {
  count             = length(local.public_subnet_cidr_blocks)
  security_group_id = aws_security_group.service.id
  cidr_ipv4         = local.public_subnet_cidr_blocks[count.index]
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080

  tags = {
    Name        = "${var.environment}-sg-ingress-rule-service-traffic-${count.index}"
    Environment = "${var.environment}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "service_management" {
  count             = length(local.public_subnet_cidr_blocks)
  security_group_id = aws_security_group.service.id
  cidr_ipv4         = local.public_subnet_cidr_blocks[count.index]
  from_port         = 9080
  ip_protocol       = "tcp"
  to_port           = 9080

  tags = {
    Name        = "${var.environment}-sg-ingress-rule-service-management-${count.index}"
    Environment = "${var.environment}"
  }
}

resource "aws_vpc_security_group_egress_rule" "service" {
  security_group_id = aws_security_group.service.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports

  tags = {
    Name        = "${var.environment}-sg-egress-rule-service"
    Environment = "${var.environment}"
  }
}



# Add egress rules to ALB so that it can talk to services in the private subnet

resource "aws_vpc_security_group_egress_rule" "alb_egress_services" {
  count             = length(local.private_subnet_cidr_blocks)
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = local.private_subnet_cidr_blocks[count.index]
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"

  tags = {
    Name        = "${var.environment}-sg-alb-egress-services-${count.index}"
    Environment = "${var.environment}"
  }
}

resource "aws_vpc_security_group_egress_rule" "alb_egress_management" {
  count             = length(local.private_subnet_cidr_blocks)
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = local.private_subnet_cidr_blocks[count.index]
  from_port         = 9080
  to_port           = 9080
  ip_protocol       = "tcp"

  tags = {
    Name        = "${var.environment}-sg-alb-egress-management-${count.index}"
    Environment = "${var.environment}"
  }
}

