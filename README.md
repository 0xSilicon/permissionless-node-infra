# Permissionless Node Infra

## Terraform
* Fullfil your own profile and run in shell
```bash
ENV="sepolia" #or mainnet
useRDS="true"
source vars/$ENV/source
```

* Initialize with s3 backend. Except 01.init
```bash
terraform init \
  -backend-config "bucket=$s3_bucket" \
  -backend-config "key=$ENV/network" \
  -backend-config "region=$aws_region" \
  -backend-config "profile=$aws_profile_name"
```

* Ensure set up the `terraform.tfvars` file correctly according to the instructions in `README.md` provided for each deployment diretories.

* Deploy
```bash
terraform plan
terraform apply
```