output "vpc_info" {
  value = {
    vpc_id = aws_vpc.this.id
    vpc_name = var.vpc.vpc_name
    cidr_block = var.vpc.cidr_block
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

output "db_subnet_info" {
  value = {
    name = aws_subnet.db[*].tags.Name
    id = aws_subnet.db[*].id
  }
}