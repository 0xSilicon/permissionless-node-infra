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

variable "s3_bucket" {
  description = "S3 bucket name used for terraform backend"
  type = string
}

variable "s3_tfstate_rds" {
  description = "S3 bucket key for rds state file"
  type = string
}

variable "s3_tfstate_ec2" {
  description = "S3 bucket key for ec2 file"
  type = string
}

variable "s3_tfstate_ec2_db" {
  description = "S3 bucket key for init rds ec2 file"
  type = string
}

variable "backup_date" {
  type = string
}

variable "master_password" {
  type = string
}