```bash
cat <<EOL > terraform.tfvars
aws_region = "$aws_region"
aws_profile_name = "$aws_profile_name"
vpc = $vpc
availability_zones = $availability_zones
skipRDS = $skipRDS
EOL
```