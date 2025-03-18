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

# terraform apply -var="restore_enabled=true"
variable "restore_enabled" {
  description = "Set to true to trigger restore"
  type        = bool
  default     = false
}

variable "backup_date" {
  type = string
  validation {
    condition     = length(var.backup_date) > 0
    error_message = "backup_date must be provided and cannot be empty."
  }
}

variable "master_password" {
  type = string
}