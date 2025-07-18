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
  ethermanurl = var.launchL1 == true ? "http://${module.l1_rpc[0].ec2_instance_info.private_ip}:8545" : var.urlOfL1
}

module "public_erigon_rpc_sg" {
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
    security_groups = [data.terraform_remote_state.load_balancer.outputs.security_group_info.id]
    cidr_blocks     = []
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
    security_groups = [ module.public_erigon_rpc_sg.security_group_info.id ]
  }, {
    from_port = 30303
    to_port = 30303
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }]

  depends_on = [ module.public_erigon_rpc_sg ]
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

locals {
  secure_rpc_setup = var.secureMode ? templatefile(
    "${path.module}/../config/${var.nameOfL1}/secure_rpc_setup.sh.tpl", 
    {
      secure_rpc_compose = "../config/${var.nameOfL1}/secure_rpc.docker-compose.yml"
    }
  ) : ""
  
  erigon_image        = "hermeznetwork/cdk-erigon:v2.61.20"
  secure_erigon_image = "theradius/radius-cdk-erigon:v1.0.2-radius"

  base_compose = file("${path.module}/../config/${var.nameOfL1}/erigon.docker-compose.yml")

  erigon_compose = var.secureMode ? replace(local.base_compose, local.erigon_image, local.secure_erigon_image) : local.base_compose
}

module "public_erigon_rpc" {
  count = 1
  source = "../modules/ec2"

  ami_id = var.instances_type.rpc.arch == "arm" == true ? local.ami_arm_id : local.ami_id
  name = "cdk-erigon-rpc"
  instance_type = var.instances_type.rpc.type

  is_public = true
  disable_api_termination = false

  subnet_id = ( var.skipNETWORK == true ?
    var.network_object.public_subnet_id :
    data.terraform_remote_state.network.outputs.public_subnet_info.id[0][0]
  )
  security_group_ids = [ module.public_erigon_rpc_sg.security_group_info.id ]
  iam_role = data.terraform_remote_state.ec2_base.outputs.ssm_info.instance_profile_name

  user_data = <<-EOF
    #!/bin/bash

    ${file("./userdata.docker.sh")}

    apt-get update
    apt-get install -y unzip curl git

    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install

    # [[ erigon rpc setup ]]
    mkdir -p config
    pushd config
    wget https://raw.githubusercontent.com/0xSilicon/permissionless-node-infra/main/config/${var.nameOfL1}/dynamic-silicon-allocs.json
    wget https://raw.githubusercontent.com/0xSilicon/permissionless-node-infra/main/config/${var.nameOfL1}/dynamic-silicon-chainspec.json
    wget https://raw.githubusercontent.com/0xSilicon/permissionless-node-infra/main/config/${var.nameOfL1}/dynamic-silicon-conf.json
    wget https://raw.githubusercontent.com/0xSilicon/permissionless-node-infra/main/config/${var.nameOfL1}/rpc.config.yaml
    echo "zkevm.l1-rpc-url: \"${local.ethermanurl}\"" | tee -a rpc.config.yaml
    popd

    echo '${replace(local.erigon_compose, "'", "'\"'\"'")}' > /home/ubuntu/docker-compose.yml

    mkdir -p /home/ubuntu/config
    mv config/*.json /home/ubuntu/config/
    mv config/rpc.config.yaml /home/ubuntu/config/

    mkdir -p /home/ubuntu/data /home/ubuntu/data/rpc /home/ubuntu/data/log
    chown -R ubuntu:ubuntu /home/ubuntu/
    chmod -R a+w /home/ubuntu/data

    sudo docker compose -f /home/ubuntu/docker-compose.yml up -d

    # [[ erigon rpc backup/restore scripts ]]
    echo '${file("../config/backup-to-s3.sh")}' > /home/ubuntu/backup-to-s3.sh
    sed -i 's|{{S3_BUCKET}}|${var.s3_bucket}|' /home/ubuntu/backup-to-s3.sh
    echo '${file("../config/restore-from-s3.sh")}' > /home/ubuntu/restore-from-s3.sh
    sed -i 's|{{S3_BUCKET}}|${var.s3_bucket}|' /home/ubuntu/restore-from-s3.sh

    # [[ secure-rpc-provider setup ]]
    ${local.secure_rpc_setup}

  EOF

  depends_on = [ module.public_erigon_rpc_sg ]
}

resource "aws_lb_target_group_attachment" "attach_public_erigon_rpc" {
  target_group_arn = data.terraform_remote_state.load_balancer.outputs.tg_info.tg_arn
  target_id        = module.public_erigon_rpc[0].ec2_instance_info.id
}