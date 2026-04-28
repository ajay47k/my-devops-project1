# ============================================================
# terraform/main.tf
# Project: my-devops-project1
# Chapter 7 Ready — S3 Backend + Clean Resource Management
# ============================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ─────────────────────────────────────────────────────────
  # CHAPTER 7 — S3 Remote Backend
  # Step 1: AWS Console mein yeh banao:
  #   - S3 Bucket:      my-devops-tfstate-679209310994  (us-east-2)
  #   - DynamoDB Table: terraform-state-lock            (LockID partition key)
  # Step 2: Neeche ka comment hato aur `terraform init -reconfigure` run karo
  # ─────────────────────────────────────────────────────────
  backend "s3" {
  bucket         = "my-devops-tfstate-679209310994"
  key            = "ecs/terraform.tfstate"
  region         = "us-east-2"
  # use_lockfile   = true
  dynamodb_table = "terraform-state-lock"
  encrypt        = true
  }
}

# ─────────────────────────────────────────────────────────
# Provider
# ─────────────────────────────────────────────────────────
provider "aws" {
  region = var.aws_region
}

# ─────────────────────────────────────────────────────────
# Variables
# ─────────────────────────────────────────────────────────
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "image_uri" {
  description = "Full ECR image URI — passed by CD pipeline"
  type        = string
}

variable "app_name" {
  description = "Application name — used for naming all resources"
  type        = string
  default     = "simple-flask-app"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "staging"
}

# ─────────────────────────────────────────────────────────
# Data Sources — existing AWS infra ko reference karo
# ─────────────────────────────────────────────────────────
data "aws_iam_role" "ecs_execution_role" {
  name = "ecsTaskExecutionRole-staging"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ─────────────────────────────────────────────────────────
# Security Group
# FIX: timestamp() hata diya — static naam use karo
# Warna har run pe naya SG banta tha = "already exists" errors
# ─────────────────────────────────────────────────────────
resource "aws_security_group" "flask_sg" {
  name        = "${var.app_name}-sg-${var.environment}"
  description = "Security group for ${var.app_name} ECS tasks"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Flask app port"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-sg-${var.environment}"
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  # Agar naam conflict ho toh — naya banao pehle, phir purana hato
  lifecycle {
    create_before_destroy = true
  }
}

# ─────────────────────────────────────────────────────────
# ECS Cluster
# ─────────────────────────────────────────────────────────
resource "aws_ecs_cluster" "staging" {
  name = "${var.app_name}-${var.environment}"

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ─────────────────────────────────────────────────────────
# ECS Task Definition
# ─────────────────────────────────────────────────────────
resource "aws_ecs_task_definition" "flask_app" {
  family                   = var.app_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = data.aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name      = var.app_name
    image     = var.image_uri
    essential = true

    portMappings = [{
      containerPort = 5000
      protocol      = "tcp"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${var.app_name}"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
        "awslogs-create-group"  = "true"
      }
    }
  }])

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ─────────────────────────────────────────────────────────
# ECS Service
# ─────────────────────────────────────────────────────────
resource "aws_ecs_service" "flask_app" {
  name            = "${var.app_name}-${var.environment}"
  cluster         = aws_ecs_cluster.staging.id
  task_definition = aws_ecs_task_definition.flask_app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.flask_sg.id]
    assign_public_ip = true
  }

  # KEY FIX: image update hone pe task definition change hoti hai
  # Terraform ko force-replace nahi karna chahiye service
  lifecycle {
    ignore_changes = [task_definition]
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ─────────────────────────────────────────────────────────
# Outputs — pipeline aur debugging ke liye useful
# ─────────────────────────────────────────────────────────
output "cluster_name" {
  description = "ECS Cluster name"
  value       = aws_ecs_cluster.staging.name
}

output "service_name" {
  description = "ECS Service name"
  value       = aws_ecs_service.flask_app.name
}

output "task_definition_family" {
  description = "Task Definition family name"
  value       = aws_ecs_task_definition.flask_app.family
}