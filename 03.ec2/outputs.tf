output "public_erigon_rpc_instance_info" {
  value = {
    name = module.public_erigon_rpc[*].ec2_instance_info.name
    id = module.public_erigon_rpc[*].ec2_instance_info.id
    private_ip = module.public_erigon_rpc[*].ec2_instance_info.private_ip
    public_ip = module.public_erigon_rpc[*].ec2_instance_info.public_ip
  }
  description = ""
}