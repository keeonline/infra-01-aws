resource "aws_ecs_cluster" "services" {
  name = "${var.environment}-ecs-cluster"

  tags = {
    Name = "${var.environment}-ecs-cluster"
    Environment = "${var.environment}"
  }

}

resource "aws_ecs_task_definition" "chameleon" {
  family = "service"
  container_definitions = jsonencode([
    {
      name      = "${var.environment}-chameleon-taskdef"
      image     = "keeonline/chameleon:latest"
      cpu       = 10
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 18080
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "chameleon" {
  name            = "${var.environment}-chameleon-service"
  cluster         = aws_ecs_cluster.services.id
  task_definition = aws_ecs_task_definition.chameleon.arn
  desired_count   = 1
#  iam_role        = aws_iam_role.foo.arn
#  depends_on      = [aws_iam_role_policy.foo]

}