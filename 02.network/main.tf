module "network" {
  count = var.skipNETWORK == true ? 0 : 1
  source = "../modules/network"

  vpc = {
    vpc_name = var.vpc.vpc_name
    cidr_block = var.vpc.cidr_block
  }
  availability_zones = var.availability_zones
  subnets = var.subnets
}