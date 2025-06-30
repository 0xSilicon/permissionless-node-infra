variable "aws_region" {
  description = "AWS region"
  type = string
  default = "ap-northeast-2"
}

variable "aws_profile_name" {
  description = "AWS profile name"
  type = string
  default = "default"
}

variable "nameOfL1" {
  type = string
}

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

module "ami_data" {
  source = "../../modules/ec2/ami"
}

output "ami_data" {
  value = {
    ubuntu = module.ami_data.object.ubuntu.id
    ubuntu_arm64 = module.ami_data.object.ubuntu_arm64.id
    amazon_linux2 = module.ami_data.object.amazon_linux2.id
  }
}

module "ssm" {
  source = "../../modules/iam/ssm"
  name = "instance-${var.nameOfL1}-role"
}

output "ssm_info" {
  value = {
    role_name = module.ssm.ssm_role_info.role_name
    role_arn = module.ssm.ssm_role_info.role_arn
    instance_profile_name = module.ssm.ssm_role_info.instance_profile_name
  }
}