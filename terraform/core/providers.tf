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
      # Environment = "${var.infra_environment}"
      Environment = "bob"
      Category    = "${var.resource_category}"
      Version     = "${var.infra_version}"
    }
  }

  ignore_tags {
    keys = ["Created"]
  }
}
