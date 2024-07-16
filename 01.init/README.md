```bash
cat <<EOL > terraform.tfvars
s3_bucket = "$s3_bucket"
aws_region = "$aws_region"
aws_profile_name = "$aws_profile_name"
EOL
```
