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
}

module "public_rpc_sg" {
  source = "../modules/ec2/securitygroup"

  name = "public-rpc-sg"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_info.vpc_id
  ingress = [{
    from_port = 8545
    to_port = 8546
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }]
}

module "sepolia_rpc_sg" {
  source = "../modules/ec2/securitygroup"

  name = "sepolia-rpc-sg"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_info.vpc_id
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
  vpc_id = data.terraform_remote_state.network.outputs.vpc_info.vpc_id
  ingress = [{
    from_port = 50061
    to_port = 50071
    protocol = "tcp"
    security_groups = [ module.public_rpc_sg.security_group_info.id ]
  }]

  depends_on = [ module.public_rpc_sg ]
}

module "sepolia_rpc" {
  count = var.launchETH ? 1 : 0
  source = "../modules/ec2"

  ami_id = local.ami_id
  name = "sepolia-rpc"
  instance_type = "m6i.large"

  disable_api_termination = false

  subnet_id = data.terraform_remote_state.network.outputs.public_subnet_info.id[0]
  security_group_ids = [ module.sepolia_rpc_sg.security_group_info.id ]
  iam_role = data.terraform_remote_state.ec2_base.outputs.ssm_info.instance_profile_name

  block_device_option = {
    size_gib = 512
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/bin/bash

    ${file("./userdata.prysm.geth.sh")}
  EOF

  depends_on = [ module.sepolia_rpc_sg ]
}

module "public_rpc" {
  count = 1
  source = "../modules/ec2"

  ami_id = local.ami_id
  name = "public-rpc"
  instance_type = "t3.micro"

  disable_api_termination = false

  subnet_id = data.terraform_remote_state.network.outputs.public_subnet_info.id[0]
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
    sed -i 's/ethermanurl/http:\/\/${module.sepolia_rpc[0].ec2_instance_info.private_ip}:8545/' docker-compose.yml
    sed -i 's/mtclienturi/${module.executor[0].ec2_instance_info.private_ip}:50061/' docker-compose.yml
    sed -i 's/executoruri/${module.executor[0].ec2_instance_info.private_ip}:50071/' docker-compose.yml

    wget https://gist.githubusercontent.com/jaybbbb/9f0b391ea2339e6996b7def6e5501476/raw/genesis.json
    wget https://raw.githubusercontent.com/0xPolygonHermez/zkevm-node/develop/config/environments/mainnet/node.config.toml
    mv docker-compose.yml /home/ssm-user/docker-compose.yml
    mv node.config.toml /home/ssm-user/node.config.toml
    mv genesis.json /home/ssm-user/genesis.json
    chown ssm-user:ssm-user /home/ssm-user/docker-compose.yml /home/ssm-user/node.config.toml /home/ssm-user/genesis.json
    docker compose -f /home/ssm-user/docker-compose.yml up -d
  EOF

  depends_on = [ module.public_rpc_sg, module.executor ]
}

module "executor" {
  count = 1
  source = "../modules/ec2"

  ami_id = local.ami_id
  name = "executor"

  instance_type = "r6i.xlarge"

  disable_api_termination = false

  subnet_id = data.terraform_remote_state.network.outputs.public_subnet_info.id[0]
  security_group_ids = [ module.executor_sg.security_group_info.id ]
  iam_role = data.terraform_remote_state.ec2_base.outputs.ssm_info.instance_profile_name

  user_data = <<-EOF
    #!/bin/bash

    ${file("./userdata.docker.sh")}

    echo '${file("./executor.docker-compose.yml")}' | tee docker-compose.yml

    wget https://raw.githubusercontent.com/0xPolygonHermez/zkevm-prover/v6.0.0/config/config_executor_and_statedb.json
    cat config_executor_and_statedb.json \
      | jq '.inputFile = "input_executor_0.json" \
      | .inputFile2 = "input_executor_1.json" \
      | .databaseURL="postgresql://prover_user:prover_pass@${data.terraform_remote_state.rds.outputs.silicon_cluster_info.endpoint[0]}:5432/prover_db"' \
      | tee config.json
    mv docker-compose.yml /home/ssm-user/docker-compose.yml
    mv config_executor_and_statedb.json /home/ssm-user/config_executor_and_statedb.json
    mv config.json /home/ssm-user/config.json
    chown ssm-user:ssm-user /home/ssm-user/docker-compose.yml /home/ssm-user/config_executor_and_statedb.json /home/ssm-user/config.json
    docker compose -f /home/ssm-user/docker-compose.yml up -d
  EOF

  depends_on = [ module.executor_sg ]
}