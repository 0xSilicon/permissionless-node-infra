data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.s3_bucket
    key    = var.s3_tfstate_network
    region = var.aws_region
    profile = var.aws_profile_name
  }
}

data "terraform_remote_state" "rds" {
  backend = "s3"
  config = {
    bucket = var.s3_bucket
    key    = var.s3_tfstate_rds
    region = var.aws_region
    profile = var.aws_profile_name
  }
}

data "terraform_remote_state" "ec2_base" {
  backend = "s3"
  config = {
    bucket = var.s3_bucket
    key    = var.s3_tfstate_ec2_base
    region = var.aws_region
    profile = var.aws_profile_name
  }
}

module "init_rds" {
  count = var.useRDS ? 1 : 0
  source = "../../modules/ec2"

  ami_id = data.terraform_remote_state.ec2_base.outputs.ami_data.ubuntu_arm64
  name = "initialize-rds"
  instance_type = "t4g.nano"

  disable_api_termination = false

  subnet_id = data.terraform_remote_state.network.outputs.public_subnet_info.id[1]
  security_group_ids = [ data.terraform_remote_state.network.outputs.vpc_info.default_sg_id ]
  iam_role = data.terraform_remote_state.ec2_base.outputs.ssm_info.instance_profile_name

  user_data = <<-EOF
    #!/bin/bash

    apt update -y
    apt dist-upgrade -y
    apt upgrade -y
    apt install postgresql -y
    apt autoremove -y

    while true; do
      id -u ssm-user
      if [ $? -eq 0 ]; then
        break
      fi
      sleep 1s
    done

    wget https://gist.githubusercontent.com/jaybbbb/f84c06eaec263731bc468b24cb5a212d/raw/single_db_server.sql -O /home/ssm-user/single_db_server.sql
    export PGPASSWORD="${var.master_password}"
    psql -h ${data.terraform_remote_state.rds.outputs.silicon_cluster_info.endpoint[0]} \
      -U ${data.terraform_remote_state.rds.outputs.silicon_cluster_info.master_username[0]} \
      -d state_db -a -f /home/ssm-user/single_db_server.sql
  EOF
}