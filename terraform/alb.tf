resource "aws_lb" "alb" {
  name_prefix = "${vars.environment}-alb"
}