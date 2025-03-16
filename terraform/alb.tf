resource "aws_lb" "alb" {
  name = "${var.environment}-alb"
  subnets = [aws_subnet.public.id]
}