output "vpc_info" {
  value = {
    vpc_id = module.network[*].vpc_info.vpc_id
    vpc_name = module.network[*].vpc_info.vpc_name
    cidr_block = module.network[*].vpc_info.cidr_block
    default_sg_id = module.network[*].vpc_info.default_sg_id
  }
  description = "vpc info"
}

output "public_subnet_info" {
  value = {
    name = module.network[*].public_subnet_info.name
    id = module.network[*].public_subnet_info.id
  }
  description = "public subnet info"
}

output "private_subnet_info" {
  value = {
    name = module.network[*].private_subnet_info.name
    id = module.network[*].private_subnet_info.id
  }
  description = "private subnet info"
}

output "availability_zones" {
  value = var.availability_zones
}