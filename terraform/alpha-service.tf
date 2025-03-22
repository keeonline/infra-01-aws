################# ALPHA SERVICE

resource "aws_ecs_task_definition" "alpha" {
  family = "${var.environment}-applications"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu       = 256
  memory    = 512
  execution_role_arn       = aws_iam_role.ecs_task_exec.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  container_definitions = jsonencode([
    {
      name      = "${var.environment}-task-alpha"
      image     = "docker.io/keeonline/chameleon:latest"
      environment = [
        {"name": "SERVICE_NAME", "value": "alpha"},
      ]
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

resource "aws_lb_target_group" "alpha" {
  name                 = "${var.environment}-tg-alpha"
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
    path                = "/alpha/actuator/health"
    port                = 9080
    protocol            = "HTTP"
  }

  tags = {
    Name = "${var.environment}-tg-alpha"
    Environment = "${var.environment}"
  }

}

resource "aws_lb_listener_rule" "alpha" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alpha.arn
  }

  condition {
    path_pattern {
      values = ["/alpha/*"]
     }
   }

}

resource "aws_security_group" "alpha" {
  name        = "${var.environment}-sg-alpha"
  description = "Security group for (alpha) ECS task running on Fargate"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name     = "${var.environment}-sg-alpha"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alpha_service" {
  security_group_id = aws_security_group.alpha.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080

  tags = {
    Name = "${var.environment}-sg-ingress-alpha-service"
    Environment = "${var.environment}"
  }

}

resource "aws_vpc_security_group_ingress_rule" "alpha_management" {
  security_group_id = aws_security_group.alpha.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 9080
  ip_protocol       = "tcp"
  to_port           = 9080

  tags = {
    Name = "${var.environment}-sg-ingress-alpha-management"
    Environment = "${var.environment}"
  }

}

resource "aws_vpc_security_group_egress_rule" "alpha" {
  security_group_id = aws_security_group.alpha.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_ecs_service" "alpha" {
  name            = "${var.environment}-ecs-service-alpha"
  cluster         = aws_ecs_cluster.applications.id
  task_definition = aws_ecs_task_definition.alpha.arn
  desired_count   = 1
  launch_type = "FARGATE"
#  iam_role        = aws_iam_role.foo.arn
#  depends_on      = [aws_iam_role_policy.foo]

  load_balancer {
    target_group_arn = aws_lb_target_group.alpha.arn
    container_name   = "${var.environment}-task-alpha"
    container_port   = 8080
  }

  network_configuration {
    security_groups  = [aws_security_group.alpha.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = false
  }
}