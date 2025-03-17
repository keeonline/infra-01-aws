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
      name      = "chameleon"
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
