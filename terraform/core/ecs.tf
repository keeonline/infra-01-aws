resource "aws_ecs_cluster" "applications" {
  name = "${var.environment}-ecs-cluster-applications"

  tags = {
    Name        = "${var.environment}-ecs-cluster-applications"
    Environment = "${var.environment}"
    Category    = "${var.resource_category}"
    Version     = "${var.iac_version}"
  }

}

