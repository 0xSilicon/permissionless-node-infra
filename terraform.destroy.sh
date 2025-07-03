#!/usr/bin/env bash

pushd vars/$ENV;
source .env
popd;

# destroy ec2
pushd 03.ec2;
terraform destroy -auto-approve;

pushd 02.ec2_lb;
terraform destroy -auto-approve;
popd;

pushd 01.ec2_base;
terraform destroy -auto-approve;
popd;
popd;

# destroy network
pushd 02.network;
terraform destroy -auto-approve;
popd;

# destroy init
pushd 01.init;
terraform destroy -auto-approve;
popd;
