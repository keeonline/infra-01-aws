resource "aws_ecs_cluster" "chameleon" {
  name = "${var.environment}-ecs-cluster-chameleon"

  tags = {
    Name = "${var.environment}-ecs-cluster-chameleon"
    Environment = "${var.environment}"
  }

}

resource "aws_lb_target_group" "bravo" {
  name                 = "${var.environment}-tg-bravo"
  port                 = 8080
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  deregistration_delay = 5
  target_type          = "ip"

  # health_check {
  #   healthy_threshold   = 2
  #   unhealthy_threshold = 2
  #   interval            = 60
  #   matcher             = var.healthcheck_matcher
  #   path                = var.healthcheck_endpoint
  #   port                = "traffic-port"
  #   protocol            = "HTTP"
  #   timeout             = 30
  # }
}

resource "aws_lb_listener_rule" "bravo" {
  listener_arn = "${aws_lb_listener.http.arn}"
  priority     = 20
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bravo.arn
  }
  condition {
    path_pattern {
      values = ["/bravo*"]
     }
   }
}

resource "aws_ecs_task_definition" "bravo" {
  family = "${var.environment}-family-chameleon"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu       = 256
  memory    = 512
  container_definitions = jsonencode([
    {
      name      = "${var.environment}-task-bravo"
      image     = "keeonline/chameleon:latest"
      environment = [
        {"name": "SERVICE_NAME", "value": "bravo"}
      ],
      cpu = 256
      memory = 512
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol = "tcp"
        }
      ]
    }
  ])

}

resource "aws_security_group" "chameleon" {
  name        = "${var.environment}-sg-http-chameleon"
  description = "Security group for ECS task running on Fargate"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow ingress traffic from ALB on HTTP only"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all egress traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "${var.environment}-sg-http-chameleon"
  }
}

resource "aws_ecs_service" "bravo" {
  name            = "${var.environment}-ecs-service-bravo"
  cluster         = aws_ecs_cluster.chameleon.id
  task_definition = aws_ecs_task_definition.bravo.arn
  desired_count   = 1
#  iam_role        = aws_iam_role.foo.arn
#  depends_on      = [aws_iam_role_policy.foo]

  load_balancer {
    target_group_arn = aws_lb_target_group.bravo.arn
    container_name   = "${var.environment}-task-bravo"
    container_port   = 8080
  }

    network_configuration {
      security_groups  = [aws_security_group.chameleon.id]
      subnets          = aws_subnet.private.*.id
      assign_public_ip = false
    }
}