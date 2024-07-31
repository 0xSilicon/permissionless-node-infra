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

variable "vpc" {
  type = object({
    vpc_name = string,
    cidr_block = string,
  })
}

variable "availability_zones" {
  type = list(string)
}

variable "subnets" {
  type = object({
    newbits = number,
    public_netnum = number,
    private_netnum = number,
    db_netnum = number,
  })
  default = {
    newbits = 8,
    public_netnum = 1,
    private_netnum = 11,
    db_netnum = 21,
  }
}

variable "useRDS" {
  type = bool
  default = false
}