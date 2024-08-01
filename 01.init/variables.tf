variable "aws_region" {
    description = "AWS profile name"
    type        = string
    default     = "default"
}

variable "aws_profile_name" {
    description = "AWS region"
    type        = string
}

variable "s3_bucket" {
    description = "S3 bucket name"
    type        = string
}