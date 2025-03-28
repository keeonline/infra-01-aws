resource "aws_ecs_task_definition" "bravo" {
  family                   = "${var.environment}-applications"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_exec.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  container_definitions = jsonencode([
    {
      name  = "${var.environment}-task-bravo"
      image = "docker.io/keeonline/chameleon:latest"
      environment = [
        { "name" : "SERVICE_NAME", "value" : "bravo" },
      ]
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
    }
  ])
}

resource "aws_lb_target_group" "bravo" {
  name                 = "${var.environment}-tg-bravo"
  port                 = 8080
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  deregistration_delay = 5
  target_type          = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    matcher             = "200"
    path                = "/bravo/actuator/health"
    port                = 9080
    protocol            = "HTTP"
  }

  tags = {
    Name        = "${var.environment}-tg-bravo"
    Environment = "${var.environment}"
  }

}

resource "aws_lb_listener_rule" "bravo" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bravo.arn
  }

  condition {
    path_pattern {
      values = ["/bravo/*"]
    }
  }

  tags = {
    Name        = "${var.environment}-alb-listener-rule-bravo"
    Environment = "${var.environment}"
  }
}

resource "aws_ecs_service" "bravo" {
  name            = "${var.environment}-ecs-service-bravo"
  cluster         = aws_ecs_cluster.applications.id
  task_definition = aws_ecs_task_definition.bravo.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.bravo.arn
    container_name   = "${var.environment}-task-bravo"
    container_port   = 8080
  }

  network_configuration {
    security_groups  = [aws_security_group.service.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = false
  }

  tags = {
    Name        = "${var.environment}-ecs-service-bravo"
    Environment = "${var.environment}"
  }
}
