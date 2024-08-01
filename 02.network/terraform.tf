terraform {
  backend "s3" {
    encrypt = true
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.57.0"
    }
  }
  required_version = ">= 1.9.1"
}

provider "aws" {
  region = var.aws_region
  profile = var.aws_profile_name
}