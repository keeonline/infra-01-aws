resource "aws_lb" "alb" {
  name_prefix = "${var.environment}"
  subnets = [for subnet in aws_subnet.public : subnet.id]
}