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

module "init_rds_sg" {
  count = var.skipRDS == true ? 0 : 1
  source = "../../modules/ec2/securitygroup"

  name = "init_rds_sg"
  vpc_id = ( var.skipNETWORK == true ?
    var.network_object.vpc_id :
    data.terraform_remote_state.network.outputs.vpc_info.vpc_id[0]
  )
}

module "init_rds" {
  count = var.skipRDS == true ? 0 : 1
  source = "../../modules/ec2"

  ami_id = data.terraform_remote_state.ec2_base.outputs.ami_data.ubuntu_arm64
  name = "initialize-rds"
  instance_type = "t4g.nano"

  is_public = true
  disable_api_termination = false

  subnet_id = ( var.skipNETWORK == true ?
    var.network_object.public_subnet_id :
    data.terraform_remote_state.network.outputs.public_subnet_info.id[0][1]
  )
  security_group_ids = [ module.init_rds_sg[count.index].security_group_info.id ]
  iam_role = data.terraform_remote_state.ec2_base.outputs.ssm_info.instance_profile_name

  user_data = <<-EOF
    #!/bin/bash

    apt update -y
    apt dist-upgrade -y
    apt upgrade -y
    apt install postgresql -y
    apt autoremove -y

    wget https://gist.githubusercontent.com/jaybbbb/f84c06eaec263731bc468b24cb5a212d/raw/single_db_server.sql
    export PGPASSWORD="${var.master_password}"
    psql -h ${data.terraform_remote_state.rds.outputs.silicon_cluster_info.endpoint[0]} \
      -U ${data.terraform_remote_state.rds.outputs.silicon_cluster_info.master_username[0]} \
      -d state_db -a -f single_db_server.sql
  EOF

  depends_on = [ module.init_rds_sg ]
}