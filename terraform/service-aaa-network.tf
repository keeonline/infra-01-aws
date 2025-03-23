data "aws_subnets" "public" {
  filter {
    name   = "tag:Environment"
    values = ["${var.environment}"]
  }

  filter {
    # name   = "tag:Name"
    # values = ["${var.environment}-subnet-public-*"]
    name   = "tag:Public"
    values = ["yes"]
  }
}

data "aws_subnet" "public" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}

locals {
  public_subnet_cidr_blocks = [for s in data.aws_subnet.public : s.cidr_block]
}

resource "aws_security_group" "service" {
  name        = "${var.environment}-sg-service"
  description = "Security group for ECS service running on Fargate"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-sg-service"
  }
}

resource "aws_vpc_security_group_ingress_rule" "service_traffic" {
  count          = length(local.public_subnet_cidr_blocks)
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
  count          = length(local.public_subnet_cidr_blocks)
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