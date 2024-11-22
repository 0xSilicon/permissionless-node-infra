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
  name = "rds-${var.nameOfL1}-role"
}

module "silicon_cluster" {
  count = var.skipRDS == true ? 0 : 1
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

  vpc_id = ( var.skipNETWORK == true ?
    var.network_object.vpc_id :
    data.terraform_remote_state.network.outputs.vpc_info.vpc_id[0]
  )
  vpc_cidr = ( var.skipNETWORK == true ?
    var.network_object.cidr_block :
    data.terraform_remote_state.network.outputs.vpc_info.cidr_block[0]
  )
  availability_zones = ( var.skipNETWORK == true ?
    var.network_object.availability_zones :
    data.terraform_remote_state.network.outputs.availability_zones
  )
  db_subnet_group_name = ( var.skipNETWORK == true ?
    var.network_object.db_subnet_group_name :
    data.terraform_remote_state.network.outputs.db_subnet_group_info.name[0]
  )

  iam_role_info = module.rds_role.rds_role_info

  depends_on = [ module.rds_role ]
}
