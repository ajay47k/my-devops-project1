terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

resource "aws_apprunner_service" "staging" {
  service_name = "simple-flask-app-staging"

  source_configuration {
    image_repository {
      image_identifier      = var.image_uri
      image_repository_type = "ECR"
      image_configuration {
        port = "5000"
      }
    }
    auto_deployments_enabled = false
  }
}

variable "image_uri" {
  description = "The full URI of the Docker image in ECR."
  type        = string
} 

output "service_url" {
  value = aws_apprunner_service.staging.service_url
}