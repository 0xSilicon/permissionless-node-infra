data "terraform_remote_state" "load_balancer" {
  backend = "s3"
  config = {
    bucket  = var.s3_bucket
    key     = var.s3_tfstate_ec2_lb
    region  = var.aws_region
    profile = var.aws_profile_name
  }
}

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

locals {
  ami_id = substr(var.ami_id, 0, 4) == "ami-" ? var.ami_id : data.terraform_remote_state.ec2_base.outputs.ami_data.ubuntu
  ami_arm_id = data.terraform_remote_state.ec2_base.outputs.ami_data.ubuntu_arm64
  ethermanurl = var.launchL1 == true ? "http:\\/\\/${module.l1_rpc[0].ec2_instance_info.private_ip}:8545" : replace(var.urlOfL1, "/", "\\/")
}

module "public_rpc_sg" {
  source = "../modules/ec2/securitygroup"

  name = "public-rpc-sg"
  vpc_id = ( var.skipNETWORK == true ?
    var.network_object.vpc_id :
    data.terraform_remote_state.network.outputs.vpc_info.vpc_id[0]
  )
  ingress = [{
    from_port = 8545
    to_port = 8546
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }]
}

module "l1_rpc_sg" {
  source = "../modules/ec2/securitygroup"

  name = "l1-rpc-sg"
  vpc_id = ( var.skipNETWORK == true ?
    var.network_object.vpc_id :
    data.terraform_remote_state.network.outputs.vpc_info.vpc_id[0]
  )
  ingress = [{
    from_port = 8545
    to_port = 8546
    protocol = "tcp"
    security_groups = [ module.public_rpc_sg.security_group_info.id ]
  }, {
    from_port = 30303
    to_port = 30303
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }]

  depends_on = [ module.public_rpc_sg ]
}

module "executor_sg" {
  source = "../modules/ec2/securitygroup"

  name = "executor-sg"
  vpc_id = ( var.skipNETWORK == true ?
    var.network_object.vpc_id :
    data.terraform_remote_state.network.outputs.vpc_info.vpc_id[0]
  )
  ingress = [{
    from_port = 50061
    to_port = 50071
    protocol = "tcp"
    security_groups = [ module.public_rpc_sg.security_group_info.id ]
  }]

  depends_on = [ module.public_rpc_sg ]
}

module "l1_rpc" {
  count = var.launchL1 ? 1 : 0
  source = "../modules/ec2"

  ami_id = var.instances_type.l1.arch == "arm" == true ? local.ami_arm_id : local.ami_id
  name = "l1-rpc"
  instance_type = var.instances_type.l1.type

  is_public = true
  disable_api_termination = false

  subnet_id = ( var.skipNETWORK == true ?
    var.network_object.public_subnet_id :
    data.terraform_remote_state.network.outputs.public_subnet_info.id[0][0]
  )
  security_group_ids = [ module.l1_rpc_sg.security_group_info.id ]
  iam_role = data.terraform_remote_state.ec2_base.outputs.ssm_info.instance_profile_name

  block_device_option = {
    size_gib = var.nameOfL1 == "mainnet" ? 2048 : 512
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/bin/bash

    ${file("../config/userdata.prysm.geth.sh")}

    wget https://raw.githubusercontent.com/0xSilicon/permissionless-node-infra/refs/heads/main/config/${var.nameOfL1}/prysm.service -O /lib/systemd/system/prysm.service
    systemctl enable prysm.service; systemctl restart prysm.service

    wget https://raw.githubusercontent.com/0xSilicon/permissionless-node-infra/refs/heads/main/config/${var.nameOfL1}/geth.service -O /lib/systemd/system/geth.service
    systemctl enable geth.service; systemctl restart geth.service
  EOF

  depends_on = [ module.l1_rpc_sg ]
}

module "public_rpc" {
  count = 1
  source = "../modules/ec2"

  ami_id = var.instances_type.rpc.arch == "arm" == true ? local.ami_arm_id : local.ami_id
  name = "public-rpc"
  instance_type = var.instances_type.rpc.type

  is_public = true
  disable_api_termination = false

  subnet_id = ( var.skipNETWORK == true ?
    var.network_object.public_subnet_id :
    data.terraform_remote_state.network.outputs.public_subnet_info.id[0][0]
  )
  security_group_ids = [ module.public_rpc_sg.security_group_info.id ]
  iam_role = data.terraform_remote_state.ec2_base.outputs.ssm_info.instance_profile_name

  user_data = <<-EOF
    #!/bin/bash

    ${file("./userdata.docker.sh")}

    echo '${file("./syncer.docker-compose.yml")}' | tee docker-compose.yml
    sed -i 's/dbuser/${data.terraform_remote_state.rds.outputs.silicon_cluster_info.master_username[0]}/' docker-compose.yml
    sed -i 's/dbpassword/${var.master_password}/' docker-compose.yml
    sed -i 's/statedb/state_db/' docker-compose.yml
    sed -i 's/pooldb/pool_db/' docker-compose.yml
    sed -i 's/dbhost/${data.terraform_remote_state.rds.outputs.silicon_cluster_info.endpoint[0]}/' docker-compose.yml
    sed -i 's/ethermanurl/${local.ethermanurl}/' docker-compose.yml
    sed -i 's/mtclienturi/${module.executor[0].ec2_instance_info.private_ip}:50061/' docker-compose.yml
    sed -i 's/executoruri/${module.executor[0].ec2_instance_info.private_ip}:50071/' docker-compose.yml

    wget https://raw.githubusercontent.com/0xSilicon/permissionless-node-infra/refs/heads/main/config/${var.nameOfL1}/genesis.json
    wget https://raw.githubusercontent.com/0xSilicon/permissionless-node-infra/refs/heads/main/config/${var.nameOfL1}/node.toml
    mv docker-compose.yml /home/ssm-user/docker-compose.yml
    mv node.toml /home/ssm-user/node.toml
    mv genesis.json /home/ssm-user/genesis.json
    chown ssm-user:ssm-user /home/ssm-user/docker-compose.yml /home/ssm-user/node.toml /home/ssm-user/genesis.json
    docker compose -f /home/ssm-user/docker-compose.yml up -d
  EOF

  depends_on = [ module.public_rpc_sg, module.executor ]
}

module "expanded_rpc" {
  count = max(var.expanded_rpc_instance_count, 0)
  source = "../modules/ec2"

  ami_id = var.instances_type.rpc.arch == "arm" == true ? local.ami_arm_id : local.ami_id
  name = "expanded-rpc"
  instance_type = var.instances_type.rpc.type

  is_public = true
  disable_api_termination = false

  subnet_id = ( var.skipNETWORK == true ?
    var.network_object.public_subnet_id :
    data.terraform_remote_state.network.outputs.public_subnet_info.id[0][0]
  )
  security_group_ids = [ module.public_rpc_sg.security_group_info.id ]
  iam_role = data.terraform_remote_state.ec2_base.outputs.ssm_info.instance_profile_name

  user_data = <<-EOF
    #!/bin/bash

    ${file("./userdata.docker.sh")}

    echo '${file("./rpc.docker-compose.yml")}' | tee docker-compose.yml
    sed -i 's/dbuser/${data.terraform_remote_state.rds.outputs.silicon_cluster_info.master_username[0]}/' docker-compose.yml
    sed -i 's/dbpassword/${var.master_password}/' docker-compose.yml
    sed -i 's/statedb/state_db/' docker-compose.yml
    sed -i 's/pooldb/pool_db/' docker-compose.yml
    sed -i 's/dbhost/${data.terraform_remote_state.rds.outputs.silicon_cluster_info.endpoint[0]}/' docker-compose.yml
    sed -i 's/ethermanurl/${local.ethermanurl}/' docker-compose.yml
    sed -i 's/mtclienturi/${module.executor[0].ec2_instance_info.private_ip}:50061/' docker-compose.yml
    sed -i 's/executoruri/${module.executor[0].ec2_instance_info.private_ip}:50071/' docker-compose.yml

    wget https://raw.githubusercontent.com/0xSilicon/permissionless-node-infra/refs/heads/main/config/${var.nameOfL1}/genesis.json
    wget https://raw.githubusercontent.com/0xSilicon/permissionless-node-infra/refs/heads/main/config/${var.nameOfL1}/node.toml
    mv docker-compose.yml /home/ssm-user/docker-compose.yml
    mv node.toml /home/ssm-user/node.toml
    mv genesis.json /home/ssm-user/genesis.json
    chown ssm-user:ssm-user /home/ssm-user/docker-compose.yml /home/ssm-user/node.toml /home/ssm-user/genesis.json
    docker compose -f /home/ssm-user/docker-compose.yml up -d
  EOF

  depends_on = [ module.public_rpc_sg, module.executor ]
}

module "executor" {
  count = max(var.executor_instance_count, 1)
  source = "../modules/ec2"

  ami_id = var.instances_type.executor.arch == "arm" == true ? local.ami_arm_id : local.ami_id
  name = "executor"

  instance_type = var.instances_type.executor.type

  is_public = true
  disable_api_termination = false

  subnet_id = ( var.skipNETWORK == true ?
    var.network_object.public_subnet_id :
    data.terraform_remote_state.network.outputs.public_subnet_info.id[0][0]
  )
  security_group_ids = [ module.executor_sg.security_group_info.id ]
  iam_role = data.terraform_remote_state.ec2_base.outputs.ssm_info.instance_profile_name

  user_data = <<-EOF
    #!/bin/bash

    ${file("./userdata.docker.sh")}

    echo '${file("./executor.docker-compose.yml")}' | tee docker-compose.yml

    wget https://raw.githubusercontent.com/0xPolygonHermez/zkevm-prover/v6.0.0/config/config_executor_and_statedb.json
    cat config_executor_and_statedb.json \
      | jq '.inputFile = "input_executor_0.json" | .inputFile2 = "input_executor_1.json" | .databaseURL="postgresql://prover_user:prover_pass@${data.terraform_remote_state.rds.outputs.silicon_cluster_info.endpoint[0]}:5432/prover_db"' \
      | tee config.json
    mv docker-compose.yml /home/ssm-user/docker-compose.yml
    mv config_executor_and_statedb.json /home/ssm-user/config_executor_and_statedb.json
    mv config.json /home/ssm-user/config.json
    chown ssm-user:ssm-user /home/ssm-user/docker-compose.yml /home/ssm-user/config_executor_and_statedb.json /home/ssm-user/config.json
    docker compose -f /home/ssm-user/docker-compose.yml up -d
  EOF

  depends_on = [ module.executor_sg ]
}

data "aws_lb_target_group" "silicon_rpc_tg" {
  name = var.lb_target_group_name
}


resource "aws_lb_target_group_attachment" "attach_public_rpc" {
  count            = 1
  target_group_arn = (var.skipLB == true ?
    data.aws_lb_target_group.silicon_rpc_tg.arn :
    data.terraform_remote_state.load_balancer.outputs.tg_info.tg_arn)
  target_id        = module.public_rpc[0].ec2_instance_info.id
}

resource "aws_lb_target_group_attachment" "attach_expanded_rpc" {
  count            = var.expanded_rpc_instance_count
  target_group_arn = (var.skipLB == true ?
    data.aws_lb_target_group.silicon_rpc_tg.arn :
    data.terraform_remote_state.load_balancer.outputs.tg_info.tg_arn)
  target_id        = module.expanded_rpc[count.index].ec2_instance_info.id
}