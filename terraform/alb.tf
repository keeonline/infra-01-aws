resource "aws_lb" "alb" {
  name = "${var.environment}-alb"
  internal = false
  subnets = [for subnet in aws_subnet.public : subnet.id]

  tags = {
    Name = "${var.environment}-alb"
    Environment = "${var.environment}"
  }
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

  tags = {
    Name = "${var.environment}-alb-listener"
    Environment = "${var.environment}"
  }
}