variable "vpc" {
  type = object({
    vpc_name = string,
    cidr_block = string,
  })
}

variable "availability_zones" { type = list(string) }

variable "subnets" {
  type = object({
    newbits = number,
    public_netnum = number,
    private_netnum = number,
    db_netnum = number,
  })
}

variable "skipRDS" { type = bool }