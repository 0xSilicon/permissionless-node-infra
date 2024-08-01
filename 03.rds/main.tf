data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.s3_bucket
    key    = var.s3_tfstate_network
    region = var.aws_region
    profile = var.aws_profile_name
  }
}

module "rds_role" {
  source = "../modules/iam/rds"
  name = "rds-role"
}

module "silicon_cluster" {
  count = var.useRDS == true ? 1 : 0
  source = "../modules/rds/cluster"

  name = var.rds_name
  engine = "aurora-postgresql"
  engine_version = "15.6"
  port = 5432
  instance_class = var.instance_class
  instance_count = var.instance_count

  database_name           = var.default_database
  master_username         = var.master_username
  master_password         = var.master_password
  backup_retention_period = 1
  deletion_protection     = true
  skip_final_snapshot     = true
  # Must be provide if skip_final_snapshot is set to false.
  # final_snapshot_identifier =  "${var.rds_name}-final-snapshot"

  pg_family = "aurora-postgresql15"

  vpc_id = data.terraform_remote_state.network.outputs.vpc_info.vpc_id
  vpc_cidr = data.terraform_remote_state.network.outputs.vpc_info.cidr_block
  # NOTE: If Terraform attempts to destroy and replace a cluster due to editing the availability zones, uncomment the lines and edit the availability zones.
  availability_zones = data.terraform_remote_state.network.outputs.availability_zones
  # availability_zones = concat(data.terraform_remote_state.network.outputs.availability_zones, ["ap-northeast-2d"])
  db_subnet_group_name = data.terraform_remote_state.network.outputs.db_subnet_group_info.name

  iam_role_info = module.rds_role.rds_role_info

  depends_on = [ module.rds_role ]
}
