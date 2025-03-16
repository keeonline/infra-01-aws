resource "aws_lb" "alb" {
  name = "${var.environment}-alb"
  subnets = [for subnet in aws_subnet.public : subnet.id]
}