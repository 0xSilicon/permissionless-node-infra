output "vpc_info" {
  value = {
    vpc_id = aws_vpc.this.id
    vpc_name = var.vpc.vpc_name
    cidr_block = var.vpc.cidr_block
    default_sg_id = aws_vpc.this.default_security_group_id
  }
}

output "public_subnet_info" {
  value = {
    name = aws_subnet.public[*].tags.Name
    id = aws_subnet.public[*].id
  }
}

output "private_subnet_info" {
  value = {
    name = aws_subnet.private[*].tags.Name
    id = aws_subnet.private[*].id
  }
}