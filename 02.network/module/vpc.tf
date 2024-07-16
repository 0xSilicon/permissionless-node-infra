resource "aws_vpc" "this" {
  cidr_block = var.vpc.cidr_block
  assign_generated_ipv6_cidr_block = false

  tags = {
    Name = var.vpc.vpc_name
  }
}