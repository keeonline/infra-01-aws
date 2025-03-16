resource "aws_lb" "alb" {
  name = "${var.environment}-alb"
  subnets = [for subnet in aws_subnet.public : subnet.id]
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
}