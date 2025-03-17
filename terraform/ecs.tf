resource "aws_ecs_cluster" "foo" {
  name = "${var.environment}-ecs-cluster"

  tags = {
    Name = "${var.environment}-ecs-cluster"
    Environment = "${var.environment}"
  }

}