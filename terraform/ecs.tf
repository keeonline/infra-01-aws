resource "aws_ecs_cluster" "chameleon" {
  name = "${var.environment}-ecs-cluster-chameleon"

  tags = {
    Name = "${var.environment}-ecs-cluster-chameleon"
    Environment = "${var.environment}"
  }

}

resource "aws_ecs_task_definition" "alpha" {
  family = "chameleon"
  requires_compatibilities = ["FARGATE"]
  cpu       = 10
  memory    = 512
  container_definitions = jsonencode([
    {
      name      = "${var.environment}-taskdef-alpha"
      image     = "keeonline/chameleon:latest"
      environment = [
        {"name": "SERVICE_NAME", "value": "alpha"}
      ],
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

resource "aws_ecs_service" "alpha" {
  name            = "${var.environment}-ecs-service-alpha"
  cluster         = aws_ecs_cluster.chameleon.id
  task_definition = aws_ecs_task_definition.alpha.arn
  desired_count   = 1
#  iam_role        = aws_iam_role.foo.arn
#  depends_on      = [aws_iam_role_policy.foo]

}

resource "aws_ecs_task_definition" "bravo" {
  family = "chameleon"
  requires_compatibilities = ["FARGATE"]
  cpu       = 10
  memory    = 512
  container_definitions = jsonencode([
    {
      name      = "${var.environment}-taskdef-bravo"
      image     = "keeonline/chameleon:latest"
      environment = [
        {"name": "SERVICE_NAME", "value": "bravo"}
      ],
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 28080
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "bravo" {
  name            = "${var.environment}-ecs-service-bravo"
  cluster         = aws_ecs_cluster.chameleon.id
  task_definition = aws_ecs_task_definition.bravo.arn
  desired_count   = 1
#  iam_role        = aws_iam_role.foo.arn
#  depends_on      = [aws_iam_role_policy.foo]

}