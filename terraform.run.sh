#!/usr/bin/env bash

ENV="sepolia" #or mainnet
useRDS="true"
launchETH="true"
pushd vars/$ENV;
source .env
popd;

# initialize
pushd 01.init;
cat <<EOL > terraform.tfvars
s3_bucket = "$s3_bucket"
aws_region = "$aws_region"
aws_profile_name = "$aws_profile_name"
EOL
terraform init;
terraform apply -auto-approve;
popd;

# network
pushd 02.network;
cat <<EOL > terraform.tfvars
aws_region = "$aws_region"
aws_profile_name = "$aws_profile_name"
vpc = $vpc
availability_zones = $availability_zones
useRDS = $useRDS
EOL
terraform init \
  -backend-config "bucket=$s3_bucket" \
  -backend-config "key=$ENV/$(basename $PWD | awk -F '.' '{print $2}').tfstate" \
  -backend-config "region=$aws_region" \
  -backend-config "profile=$aws_profile_name";
terraform apply -auto-approve;
popd;

# rds
pushd 03.rds;
cat <<EOL > terraform.tfvars
aws_region = "$aws_region"
aws_profile_name = "$aws_profile_name"
useRDS = $useRDS
s3_bucket = "$s3_bucket"
s3_tfstate_network = "$s3_tfstate_network"
rds_name = "$rds_name"
master_username = "$master_username"
master_password = "$master_password"
EOL
terraform init \
  -backend-config "bucket=$s3_bucket" \
  -backend-config "key=$ENV/$(basename $PWD | awk -F '.' '{print $2}').tfstate" \
  -backend-config "region=$aws_region" \
  -backend-config "profile=$aws_profile_name";
terraform apply #-auto-approve; TODO: remove comment. still have bug for destroy and replace caused by availability zone
popd;

# ec2
pushd 04.ec2;
## base
pushd 01.ec2_base;
cat <<EOL > terraform.tfvars
aws_region = "$aws_region"
aws_profile_name = "$aws_profile_name"
EOL
terraform init \
  -backend-config "bucket=$s3_bucket" \
  -backend-config "key=$ENV/$(basename $PWD | awk -F '.' '{print $2}').tfstate" \
  -backend-config "region=$aws_region" \
  -backend-config "profile=$aws_profile_name";
terraform apply -auto-approve;
popd;
## db init script
pushd 02.ec2_db;
cat <<EOL > terraform.tfvars
aws_region = "$aws_region"
aws_profile_name = "$aws_profile_name"
useRDS = $useRDS
s3_bucket = "$s3_bucket"
s3_tfstate_network = "$s3_tfstate_network"
s3_tfstate_rds = "$s3_tfstate_rds"
s3_tfstate_ec2_base = "$s3_tfstate_ec2_base"
master_password = "$master_password"
EOL
terraform init \
  -backend-config "bucket=$s3_bucket" \
  -backend-config "key=$ENV/$(basename $PWD | awk -F '.' '{print $2}').tfstate" \
  -backend-config "region=$aws_region" \
  -backend-config "profile=$aws_profile_name";
terraform apply -auto-approve;
popd;
## launch rpc / executor
cat <<EOL > terraform.tfvars
aws_region = "$aws_region"
aws_profile_name = "$aws_profile_name"

useRDS = $useRDS
s3_bucket = "$s3_bucket"
s3_tfstate_network = "$s3_tfstate_network"
s3_tfstate_rds = "$s3_tfstate_rds"
s3_tfstate_ec2_base = "$s3_tfstate_ec2_base"

master_password = "$master_password"
EOL
terraform init \
  -backend-config "bucket=$s3_bucket" \
  -backend-config "key=$ENV/$(basename $PWD | awk -F '.' '{print $2}').tfstate" \
  -backend-config "region=$aws_region" \
  -backend-config "profile=$aws_profile_name";
terraform apply -auto-approve;
popd;