#!/usr/bin/env bash

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
terraform plan;
popd;

# network
pushd 02.network;
cat <<EOL > terraform.tfvars
aws_region = "$aws_region"
aws_profile_name = "$aws_profile_name"
skipRDS = $skipRDS
skipNETWORK = $skipNETWORK
availability_zones = $availability_zones
EOL
if [ ! -z "$vpc" ]; then
  echo "vpc = $vpc" >> terraform.tfvars
fi
terraform init \
  -backend-config "bucket=$s3_bucket" \
  -backend-config "key=$ENV/$(basename $PWD | awk -F '.' '{print $2}').tfstate" \
  -backend-config "region=$aws_region" \
  -backend-config "profile=$aws_profile_name";
terraform plan;
popd;

# rds
pushd 03.rds;
cat <<EOL > terraform.tfvars
aws_region = "$aws_region"
aws_profile_name = "$aws_profile_name"
nameOfL1 = "$ENV"
skipRDS = $skipRDS
skipNETWORK = $skipNETWORK
s3_bucket = "$s3_bucket"
s3_tfstate_network = "$s3_tfstate_network"
rds_name = "$rds_name"
master_username = "$master_username"
master_password = "$master_password"
EOL
if [ ! -z "$network" ]; then
  echo "network_object = $network" >> terraform.tfvars
fi
terraform init \
  -backend-config "bucket=$s3_bucket" \
  -backend-config "key=$ENV/$(basename $PWD | awk -F '.' '{print $2}').tfstate" \
  -backend-config "region=$aws_region" \
  -backend-config "profile=$aws_profile_name";
terraform plan;
popd;

# ec2
pushd 04.ec2;
## base
pushd 01.ec2_base;
cat <<EOL > terraform.tfvars
aws_region = "$aws_region"
aws_profile_name = "$aws_profile_name"
nameOfL1 = "$ENV"
EOL
terraform init \
  -backend-config "bucket=$s3_bucket" \
  -backend-config "key=$ENV/$(basename $PWD | awk -F '.' '{print $2}').tfstate" \
  -backend-config "region=$aws_region" \
  -backend-config "profile=$aws_profile_name";
terraform plan;
popd;
## db init script
pushd 02.ec2_db;
cat <<EOL > terraform.tfvars
aws_region = "$aws_region"
aws_profile_name = "$aws_profile_name"
skipRDS = $skipRDS
skipNETWORK = $skipNETWORK
s3_bucket = "$s3_bucket"
s3_tfstate_network = "$s3_tfstate_network"
s3_tfstate_rds = "$s3_tfstate_rds"
s3_tfstate_ec2_base = "$s3_tfstate_ec2_base"
master_password = "$master_password"
EOL
if [ ! -z "$network" ]; then
  echo "network_object = $network" >> terraform.tfvars
fi
terraform init \
  -backend-config "bucket=$s3_bucket" \
  -backend-config "key=$ENV/$(basename $PWD | awk -F '.' '{print $2}').tfstate" \
  -backend-config "region=$aws_region" \
  -backend-config "profile=$aws_profile_name";
terraform plan;
popd;

## ec2 lb init script
pushd 03.ec2_lb;
cat <<EOL > terraform.tfvars
aws_region = "$aws_region"
aws_profile_name = "$aws_profile_name"

s3_bucket = "$s3_bucket"
s3_tfstate_network = "$s3_tfstate_network"
s3_tfstate_rds = "$s3_tfstate_rds"
s3_tfstate_ec2_base = "$s3_tfstate_ec2_base"
s3_tfstate_ec2_lb = "$s3_tfstate_ec2_lb"

skipNETWORK = $skipNETWORK
lb_name = "$lb_name"
lb_target_group_name = "$lb_target_group_name"
lb_security_group_name = "$lb_security_group_name"

domain_name = "$domain_name"
EOL
if [ ! -z "$network" ]; then
  echo "network_object = $network" >> terraform.tfvars
fi
terraform init \
  -backend-config "bucket=$s3_bucket" \
  -backend-config "key=$ENV/$(basename $PWD | awk -F '.' '{print $2}').tfstate" \
  -backend-config "region=$aws_region" \
  -backend-config "profile=$aws_profile_name";
terraform plan;
popd;

## launch rpc / executor
cat <<EOL > terraform.tfvars
aws_region = "$aws_region"
aws_profile_name = "$aws_profile_name"
nameOfL1 = "$ENV"

s3_bucket = "$s3_bucket"
s3_tfstate_network = "$s3_tfstate_network"
s3_tfstate_rds = "$s3_tfstate_rds"
s3_tfstate_ec2_base = "$s3_tfstate_ec2_base"
s3_tfstate_ec2_lb = "$s3_tfstate_ec2_lb"

launchL1 = $launchL1
urlOfL1 = "$urlOfL1"
skipRDS = $skipRDS
skipNETWORK = $skipNETWORK

master_password = "$master_password"

instances_type = $instances_type

skipLB = $skipLB
lb_name = "$lb_name"
lb_target_group_name = "$lb_target_group_name"
EOL
if [ ! -z "$network" ]; then
  echo "network_object = $network" >> terraform.tfvars
fi
terraform init \
  -backend-config "bucket=$s3_bucket" \
  -backend-config "key=$ENV/$(basename $PWD | awk -F '.' '{print $2}').tfstate" \
  -backend-config "region=$aws_region" \
  -backend-config "profile=$aws_profile_name";
terraform plan;
popd;