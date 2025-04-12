resource "aws_ecs_cluster" "applications" {
  name = "${var.infra_environment}-ecs-cluster-applications"

  tags = {
    Name        = "${var.infra_environment}-ecs-cluster-applications"
    Environment = "${var.infra_environment}"
    Category    = "${var.resource_category}"
    Version     = "${var.infra_version}"
  }

}

