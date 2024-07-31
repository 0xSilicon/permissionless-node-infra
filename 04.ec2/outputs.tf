output "sepolia_rpc_instance_info" {
  value = {
    name = module.sepolia_rpc[*].ec2_instance_info.name
    id = module.sepolia_rpc[*].ec2_instance_info.id
    private_ip = module.sepolia_rpc[*].ec2_instance_info.private_ip
    public_ip = module.sepolia_rpc[*].ec2_instance_info.public_ip
  }
  description = ""
}

output "public_rpc_instance_info" {
  value = {
    name = module.public_rpc[*].ec2_instance_info.name
    id = module.public_rpc[*].ec2_instance_info.id
    private_ip = module.public_rpc[*].ec2_instance_info.private_ip
    public_ip = module.public_rpc[*].ec2_instance_info.public_ip
  }
  description = ""
}