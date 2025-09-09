# Configure the AWS Provider
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources for existing VPC and subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security group for EFS
resource "aws_security_group" "efs" {
  name_prefix = "${var.project_name}-efs-"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "NFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-efs-sg"
    Environment = var.environment
  }
}

# EFS Module Usage
module "efs" {
  source = "../../modules/efs"

  name               = "${var.project_name}-efs"
  subnet_ids         = data.aws_subnets.default.ids
  security_group_ids = [aws_security_group.efs.id]

  # Optional configurations
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  # Access points for different applications
  access_points = {
    web = {
      posix_user = {
        gid = 1000
        uid = 1000
      }
      root_directory = {
        path = "/web"
        creation_info = {
          owner_gid   = 1000
          owner_uid   = 1000
          permissions = "755"
        }
      }
    }
    app = {
      posix_user = {
        gid = 1001
        uid = 1001
      }
      root_directory = {
        path = "/app"
        creation_info = {
          owner_gid   = 1001
          owner_uid   = 1001
          permissions = "755"
        }
      }
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}
