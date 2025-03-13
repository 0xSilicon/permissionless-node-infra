output "init_rds_instance" {
  value = {
    name = module.init_rds[*].ec2_instance_info.name
    id = module.init_rds[*].ec2_instance_info.id
    private_ip = module.init_rds[*].ec2_instance_info.private_ip
    public_ip = module.init_rds[*].ec2_instance_info.public_ip
  }
  description = "Initialize RDS EC2 instance information"
}
