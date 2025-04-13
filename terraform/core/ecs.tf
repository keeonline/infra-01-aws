resource "aws_ecs_cluster" "applications" {
  name = "${var.infra_environment}-ecs-cluster-applications"

  tags = {
    Name    = "${var.infra_environment}-ecs-cluster-applications"
    # Created = "${timestamp()}"
  }

}

