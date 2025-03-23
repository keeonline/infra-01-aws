resource "aws_ecs_task_definition" "alpha" {
  family                   = "${var.environment}-applications"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_exec.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  container_definitions = jsonencode([
    {
      name  = "${var.environment}-task-alpha"
      image = "docker.io/keeonline/chameleon:latest"
      environment = [
        { "name" : "SERVICE_NAME", "value" : "alpha" },
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
    Name        = "${var.environment}-tg-alpha"
    Environment = "${var.environment}"
  }
}

resource "aws_lb_listener_rule" "alpha" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alpha.arn
  }

  condition {
    path_pattern {
      values = ["/alpha/*"]
    }
  }

  tags = {
    Name        = "${var.environment}-alb-listener-rule-alpha"
    Environment = "${var.environment}"
  }
}

# resource "aws_security_group" "alpha" {
#   name        = "${var.environment}-sg-alpha"
#   description = "Security group for (alpha) ECS task running on Fargate"
#   vpc_id      = aws_vpc.main.id

#   tags = {
#     Name = "${var.environment}-sg-alpha"
#   }
# }

# resource "aws_vpc_security_group_ingress_rule" "alpha_service" {
#   count          = length(local.public_subnet_cidr_blocks)
#   security_group_id = aws_security_group.alpha.id
#   cidr_ipv4         = local.public_subnet_cidr_blocks[count.index]
#   from_port         = 8080
#   ip_protocol       = "tcp"
#   to_port           = 8080

#   tags = {
#     Name        = "${var.environment}-sg-ingress-rule-alpha-service-${count.index}"
#     Environment = "${var.environment}"
#   }
# }

# resource "aws_vpc_security_group_ingress_rule" "alpha_management" {
#   count          = length(local.public_subnet_cidr_blocks)
#   security_group_id = aws_security_group.alpha.id
#   cidr_ipv4         = local.public_subnet_cidr_blocks[count.index]
#   from_port         = 9080
#   ip_protocol       = "tcp"
#   to_port           = 9080

#   tags = {
#     Name        = "${var.environment}-sg-ingress-rule-alpha-management-${count.index}"
#     Environment = "${var.environment}"
#   }
# }

# resource "aws_vpc_security_group_egress_rule" "alpha" {
#   security_group_id = aws_security_group.alpha.id
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "-1" # semantically equivalent to all ports

#   tags = {
#     Name        = "${var.environment}-sg-egress-rule-alpha-management"
#     Environment = "${var.environment}"
#   }
# }

resource "aws_ecs_service" "alpha" {
  name            = "${var.environment}-ecs-service-alpha"
  cluster         = aws_ecs_cluster.applications.id
  task_definition = aws_ecs_task_definition.alpha.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.alpha.arn
    container_name   = "${var.environment}-task-alpha"
    container_port   = 8080
  }

  network_configuration {
    security_groups  = [aws_security_group.service.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = false
  }

  tags = {
    Name        = "${var.environment}-ecs-service-alpha"
    Environment = "${var.environment}"
  }
}
