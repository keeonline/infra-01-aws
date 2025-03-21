resource "aws_ecs_cluster" "chameleon" {
  name = "${var.environment}-ecs-cluster-chameleon"

  tags = {
    Name = "${var.environment}-ecs-cluster-chameleon"
    Environment = "${var.environment}"
  }

}

resource "aws_lb_target_group" "chameleon" {
  name                 = "${var.environment}-tg-chameleon"
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
    path                = "/chameleon/actuator/health"
    port                = 9080
    protocol            = "HTTP"
  }

  tags = {
    Name = "${var.environment}-tg-chameleon"
    Environment = "${var.environment}"
  }

}

#############  REALLY IMPORTANT !!!  Add an OUTBOUND SG rule to the ALB SECURITY GROUP so the ALB can access the service

resource "aws_vpc_security_group_egress_rule" "alb_chameleon_service" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"

  tags = {
    Name = "${var.environment}-sg-rule-alb-chameleon-svc"
    Environment = "${var.environment}"
  }
}

resource "aws_vpc_security_group_egress_rule" "alb_chameleon_management" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 9080
  to_port           = 9080
  ip_protocol       = "tcp"

  tags = {
    Name = "${var.environment}-sg-rule-alb-chameleon-mgmt"
    Environment = "${var.environment}"
  }
}


resource "aws_lb_listener_rule" "chameleon" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.chameleon.arn
  }
  condition {
    path_pattern {
      values = ["/chameleon/*"]
     }
   }
}

resource "aws_ecs_task_definition" "chameleon" {
  family = "${var.environment}-family-chameleon"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu       = 1024
  memory    = 2048
  execution_role_arn       = aws_iam_role.ecs_task_exec.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  container_definitions = jsonencode([
    {
      name      = "${var.environment}-task-chameleon"
      image     = "docker.io/keeonline/chameleon:latest"
      # environment = [
      #   {"name": "SERVICE_NAME", "value": "chameleon"},
      #   {"name": "NOT_USED", "value": "n/a"}
      # ]
      cpu = 1024
      memory = 2048
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

  # ingress {
  #   description     = "Allow application ingress traffic from ALB on HTTP only"
  #   from_port       = 8080
  #   to_port         = 8080
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.alb.id]
  # }

  # ingress {
  #   description     = "Allow actuator ingress traffic from ALB on HTTP only"
  #   from_port       = 9080
  #   to_port         = 9080
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.alb.id]
  # }

  # egress {
  #   description = "Allow all egress traffic"
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = -1
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  tags = {
    Name     = "${var.environment}-sg-http-chameleon"
  }
}

resource "aws_vpc_security_group_ingress_rule" "chameleon_service" {
  security_group_id = aws_security_group.chameleon.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}

resource "aws_vpc_security_group_ingress_rule" "chameleon_management" {
  security_group_id = aws_security_group.chameleon.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 9080
  ip_protocol       = "tcp"
  to_port           = 9080
}

resource "aws_vpc_security_group_egress_rule" "chameleon" {
  security_group_id = aws_security_group.chameleon.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_ecs_service" "chameleon" {
  name            = "${var.environment}-ecs-service-chameleon"
  cluster         = aws_ecs_cluster.chameleon.id
  task_definition = aws_ecs_task_definition.chameleon.arn
  desired_count   = 1
  launch_type = "FARGATE"
#  iam_role        = aws_iam_role.foo.arn
#  depends_on      = [aws_iam_role_policy.foo]

  load_balancer {
    target_group_arn = aws_lb_target_group.chameleon.arn
    container_name   = "${var.environment}-task-chameleon"
    container_port   = 8080
  }

  network_configuration {
    security_groups  = [aws_security_group.chameleon.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = false
  }
}