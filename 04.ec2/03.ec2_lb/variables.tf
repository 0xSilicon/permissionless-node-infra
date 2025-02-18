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

variable "s3_tfstate_rds" {
  description = "S3 bucket key for rds state file"
  type = string
}

variable "s3_tfstate_ec2_base" {
  description = "S3 bucket key for network state file"
  type = string
}

variable "skipNETWORK" {
  type = bool
  default = false
}

variable "domain_name" {
  type = string
  default = ""
}

variable "network_object" {
  type = object({
    vpc_id = string
    public_subnet_id = string
  })
  default = {
    vpc_id = ""
    public_subnet_id = ""
  }
}