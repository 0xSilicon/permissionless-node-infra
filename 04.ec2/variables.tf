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

variable "s3_tfstate_ec2_lb" {
  description = "S3 bucket key for load balancer state file"
  type = string
}


variable "ami_id" {
  type = string
  default = ""
}

variable "skipRDS" {
  type = bool
  default = false
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

variable "skipLB" {
  type = bool
  default = false
}

variable "lb_name" {
  description = "The name of the load balancer"
  type        = string
}

variable "lb_target_group_name" {
  description = "The name of the target group"
  type        = string
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

variable "master_password" {
  type = string
}

variable "instances_type" {
  type = object({
    rpc = object({
      type = string
      arch = string
    })
    executor = object({
      type = string
      arch = string
    })
    l1 = optional(object({
      type = string
      arch = string
    }))
  })
}

// terraform apply -auto-approve -var="expanded_rpc_instance_count=1" -var="executor_instance_count=2"
variable "expanded_rpc_instance_count" {
  description = "value of expanded_rpc instance count"
  type = number
  default = 0
}

variable "executor_instance_count" {
  description = "value of executor instance count"
  type = number
  default = 1

  validation {
    condition     = var.executor_instance_count >= 1
    error_message = "executor_instance_count must be at least 1."
  }
}