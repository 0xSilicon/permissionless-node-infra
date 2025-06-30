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

variable "s3_tfstate_ec2_base" {
  description = "S3 bucket key for network state file"
  type = string
}

variable "s3_tfstate_ec2_lb" {
  description = "S3 bucket key for load balancer state file"
  type = string
}


variable "ami_id" {
  type = string
  default = ""
}

variable "skipNETWORK" {
  type = bool
  default = false
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

variable "launchL1" {
  type = bool
  default = true
}

variable "nameOfL1" {
  type = string
  default = ""

  validation {
    condition = var.launchL1 == false || var.nameOfL1 == "sepolia" || var.nameOfL1 == "mainnet"
    error_message = "launchL1 variable is true. then nameOfL1 must be sepolia or mainnet."
  }
}

variable "urlOfL1" {
  type = string
  default = ""
}

variable "instances_type" {
  type = object({
    rpc = object({
      type = string
      arch = string
    })
    l1 = object({
      type = string
      arch = string
    })
  })
}