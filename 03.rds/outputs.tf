output "silicon_cluster_info" {
  value = {
    id = module.silicon_cluster[*].rds_cluster_info.id
    endpoint = module.silicon_cluster[*].rds_cluster_info.endpoint
    reader_endpoint = module.silicon_cluster[*].rds_cluster_info.reader_endpoint
    engine = module.silicon_cluster[*].rds_cluster_info.engine
    version = module.silicon_cluster[*].rds_cluster_info.version
    port = module.silicon_cluster[*].rds_cluster_info.port
    master_username = module.silicon_cluster[*].rds_cluster_info.master_username
    members = module.silicon_cluster[*].rds_cluster_instance_info
  }
}