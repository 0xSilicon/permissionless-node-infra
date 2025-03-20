data "terraform_remote_state" "rds" {
  backend = "s3"
  config = {
    bucket  = var.s3_bucket
    key     = var.s3_tfstate_rds
    region  = var.aws_region
    profile = var.aws_profile_name
  }
}

data "terraform_remote_state" "ec2" {
  backend = "s3"
  config = {
    bucket  = var.s3_bucket
    key     = var.s3_tfstate_ec2
    region  = var.aws_region
    profile = var.aws_profile_name
  }
}

data "terraform_remote_state" "ec2_db" {
  backend = "s3"
  config = {
    bucket  = var.s3_bucket
    key     = var.s3_tfstate_ec2_db
    region  = var.aws_region
    profile = var.aws_profile_name
  }
}
resource "aws_ssm_document" "stop_docker" {
  name            = "StopDocker"
  document_type   = "Command"
  document_format = "YAML"

  content = <<EOT
schemaVersion: "2.2"
description: "Restart Docker containers using SSM"
mainSteps:
  - action: "aws:runShellScript"
    name: "restart_docker_script"
    inputs:
      runCommand:
        - "#!/bin/bash"
        - "echo Stop Docker containers on $(hostname)..."
        - "cd /home/ssm-user && sudo docker compose stop"
EOT
}

resource "aws_ssm_document" "restore_rds" {
  name            = "RestoreRDS"
  document_type   = "Command"
  document_format = "YAML"
  content         = <<EOT
schemaVersion: "2.2"
description: "Restore RDS from S3 Backup"
mainSteps:
  - action: "aws:runShellScript"
    name: "restore_rds_script"
    inputs:
      runCommand:
        - "#!/bin/bash"
        - "echo 'Checking required variables...'"
        - "if [ -z \"${var.backup_date}\" ]; then echo 'Error: backup_date variable is missing!' >&2; exit 1; fi"
        - "BACKUP_DATE=${var.backup_date}"
        - "S3_BUCKET=chaindata-sepolia.silicon.network"
        - "DB_HOST=${data.terraform_remote_state.rds.outputs.silicon_cluster_info.endpoint[0]}"
        - "DB_USER=${data.terraform_remote_state.rds.outputs.silicon_cluster_info.master_username[0]}"
        - "export PGPASSWORD=${var.master_password}"
        - "psql -h \"$DB_HOST\" -U \"$DB_USER\" -d state_db -c 'DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;'"
        - "psql -h \"$DB_HOST\" -U \"$DB_USER\" -d state_db -c 'DROP SCHEMA IF EXISTS state CASCADE; CREATE SCHEMA state;'"
        - "psql -h \"$DB_HOST\" -U \"$DB_USER\" -d prover_db -c 'DROP SCHEMA IF EXISTS state CASCADE; CREATE SCHEMA state;'"
        - "psql -h \"$DB_HOST\" -U \"$DB_USER\" -d prover_db -c 'DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;'"
        - "echo 'Restoring state_db from S3...'"
        - "aws s3 cp \"s3://$S3_BUCKET/$BACKUP_DATE.state.sql.gz\" - | zcat | psql -h \"$DB_HOST\" -U \"$DB_USER\" -d state_db || { echo 'state_db restore file error.' >&2; exit 1; }"
        - "echo 'Restoring prover_db from S3...'"
        - "aws s3 cp \"s3://$S3_BUCKET/$BACKUP_DATE.prover.sql.gz\" - | zcat | psql -h \"$DB_HOST\" -U \"$DB_USER\" -d prover_db || { echo 'prover_db restore file error.' >&2; exit 1; }"
EOT
}

resource "aws_ssm_document" "restart_docker" {
  name            = "RestartDocker"
  document_type   = "Command"
  document_format = "YAML"

  content = <<EOT
schemaVersion: "2.2"
description: "Restart Docker containers using SSM"
mainSteps:
  - action: "aws:runShellScript"
    name: "restart_docker_script"
    inputs:
      runCommand:
        - "#!/bin/bash"
        - "echo Restarting Docker containers on $(hostname)..."
        - "cd /home/ssm-user && sudo docker compose up -d --force-recreate"
EOT
}

resource "terraform_data" "stop_docker" {
  triggers_replace = {
    timestamp = timestamp() # Apply할 때마다 실행되도록 변경 감지
  }

  provisioner "local-exec" {
    command = <<EOT
aws ssm send-command \
  --document-name "${aws_ssm_document.stop_docker.name}" \
  --targets "Key=instanceIds,Values=${join(",", [data.terraform_remote_state.ec2.outputs.executor_instance_info.id[0], data.terraform_remote_state.ec2.outputs.public_rpc_instance_info.id[0]])}" \
  --comment "Stopping Docker via Terraform" \
  --region ${var.aws_region} \
  --profile ${var.aws_profile_name} \
  --output-s3-bucket-name ${var.s3_bucket} \
  --output-s3-key-prefix "ssm-logs/" \
  --output json > stop_docker_result.json
EOT
  }
}

resource "terraform_data" "restore_rds" {
  triggers_replace = {
    timestamp = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOT
aws ssm send-command \
  --document-name "${aws_ssm_document.restore_rds.name}" \
  --targets "Key=instanceIds,Values=${data.terraform_remote_state.ec2_db.outputs.init_rds_instance.id[0]}" \
  --comment "Restoring RDS via Terraform" \
  --region ${var.aws_region} \
  --profile ${var.aws_profile_name} \
  --output-s3-bucket-name ${var.s3_bucket} \
  --output-s3-key-prefix "ssm-logs/" \
  --output json > restore_rds_result.json
EOT
  }
}

resource "terraform_data" "restart_docker" {
  triggers_replace = {
    timestamp = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOT
aws ssm send-command \
  --document-name "${aws_ssm_document.restart_docker.name}" \
  --targets "Key=instanceIds,Values=${join(",", [data.terraform_remote_state.ec2.outputs.executor_instance_info.id[0], data.terraform_remote_state.ec2.outputs.public_rpc_instance_info.id[0]])}" \
  --comment "Restarting Docker via Terraform" \
  --region ${var.aws_region} \
  --profile ${var.aws_profile_name} \
  --output-s3-bucket-name ${var.s3_bucket} \
  --output-s3-key-prefix "ssm-logs/" \
  --output json > restart_docker_result.json
EOT
  }
}