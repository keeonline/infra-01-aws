resource "aws_lb" "alb" {
  name_prefix = "${var.environment}-alb"
  subnets = [aws_subnet.public.id]
}