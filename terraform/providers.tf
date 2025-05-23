terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.87.0"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      Environment = "${var.infra_environment}"
      Category    = "${var.resource_category}"
      Version     = "${var.infra_version}"
      ManagedBy   = "IaC"
      # TODO:
      # IacRepository = ...
    }
  }
}
