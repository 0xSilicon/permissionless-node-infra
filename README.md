# Permissionless Node Infra Deploy

## Terraform
* Make .env file in your target network directory. 
```bash
ENV="sepolia" #or mainnet
useRDS="true"
launchETH="true"
pushd vars/$ENV;
source .env
popd;
```

* Initialize with s3 backend. Except 01.init
```bash
terraform init \
  -backend-config "bucket=$s3_bucket" \
  -backend-config "key=$ENV/$(basename $PWD | awk -F '.' '{print $2}').tfstate" \
  -backend-config "region=$aws_region" \
  -backend-config "profile=$aws_profile_name"
```

* Ensure set up the `terraform.tfvars` file correctly according to the instructions in `README.md` provided for each deployment diretories.

* Deploy
```bash
terraform plan
terraform apply
```
