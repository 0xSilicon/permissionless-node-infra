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

variable "s3_tfstate_network" {
  description = "S3 bucket key for network state file"
  type = string
}

variable "useRDS" {
  type = bool
  default = true
}

variable "rds_name" {
  type = string
}

variable "instance_class" {
    type = string
    default = "db.r6g.large"
}

variable "instance_count" {
    type = number
    default = 1
}

variable "default_database" {
  type = string
  default = "state_db"
}

variable "master_username" {
  type = string
  default = "silicon_user"
}

variable "master_password" {
  type = string
  default = "silicon_password"
}