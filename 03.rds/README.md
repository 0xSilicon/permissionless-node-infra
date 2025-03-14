```bash
cat <<EOL > terraform.tfvars
aws_region = "$aws_region"
aws_profile_name = "$aws_profile_name"
skipRDS = $skipRDS
s3_bucket = "$s3_bucket"
s3_tfstate_network = "$s3_tfstate_network"
rds_name = "$rds_name"
master_username = "$master_username"
master_password = "$master_password"
EOL
```

## Caution
* Change `skip_final_snapshot` is set to `false`. [Read Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance#final_snapshot_identifier)
* Terraform's AWS RDS management is suck. Every plan suggests creating a new cluster due to the `availability_zones` issue.

## Option tfvars
