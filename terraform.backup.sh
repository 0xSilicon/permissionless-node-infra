#!/usr/bin/env bash

pushd vars/$ENV;
source .env
popd;

# rds_backup
pushd modules/rds/backup;
cat <<EOL > terraform.tfvars
aws_region = "$aws_region"
aws_profile_name = "$aws_profile_name"

s3_bucket = "$s3_bucket"
s3_tfstate_rds = "$s3_tfstate_rds"
s3_tfstate_ec2 = "$s3_tfstate_ec2"
s3_tfstate_ec2_db = "$s3_tfstate_ec2_db"

master_password = "$master_password"

backup_date = "$backup_date"
EOL
if [ ! -z "$network" ]; then
  echo "network_object = $network" >> terraform.tfvars
fi
terraform init -upgrade\
  -backend-config "bucket=$s3_bucket" \
  -backend-config "key=$ENV/$(basename $PWD | awk -F '.' '{print $2}').tfstate" \
  -backend-config "region=$aws_region" \
  -backend-config "profile=$aws_profile_name";
terraform plan;
popd;