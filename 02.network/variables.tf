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

variable "skipNETWORK" {
  type = bool
  default = false
}

variable "vpc" {
  type = object({
    vpc_name = string,
    cidr_block = string,
  })
  default = {
    vpc_name = ""
    cidr_block = ""
  }
}

variable "availability_zones" {
  type = list(string)
}

variable "subnets" {
  type = object({
    newbits = number,
    public_netnum = number,
    private_netnum = number
  })
  default = {
    newbits = 8,
    public_netnum = 1,
    private_netnum = 11
  }
}