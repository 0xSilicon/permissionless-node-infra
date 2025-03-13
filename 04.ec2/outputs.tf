output "l1_rpc_instance_info" {
  value = {
    name = module.l1_rpc[*].ec2_instance_info.name
    id = module.l1_rpc[*].ec2_instance_info.id
    private_ip = module.l1_rpc[*].ec2_instance_info.private_ip
    public_ip = module.l1_rpc[*].ec2_instance_info.public_ip
  }
  description = ""
}

output "executor_instance_info" {
  value = {
    name = module.executor[*].ec2_instance_info.name
    id = module.executor[*].ec2_instance_info.id
    private_ip = module.executor[*].ec2_instance_info.private_ip
    public_ip = module.executor[*].ec2_instance_info.public_ip
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

output "expanded_rpc_instance_info" {
  value = {
    name = module.expanded_rpc[*].ec2_instance_info.name
    id = module.expanded_rpc[*].ec2_instance_info.id
    private_ip = module.expanded_rpc[*].ec2_instance_info.private_ip
    public_ip = module.expanded_rpc[*].ec2_instance_info.public_ip
  }
  description = ""
}