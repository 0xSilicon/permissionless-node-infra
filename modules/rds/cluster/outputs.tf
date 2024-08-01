output "rds_cluster_info" {
  value = {
    id = aws_rds_cluster.this.id
    endpoint = aws_rds_cluster.this.endpoint
    reader_endpoint = aws_rds_cluster.this.reader_endpoint
    engine = aws_rds_cluster.this.engine
    version = aws_rds_cluster.this.engine_version_actual
    port = aws_rds_cluster.this.port
    master_username = aws_rds_cluster.this.master_username
  }
}

output "rds_cluster_instance_info" {
  value = {
    id = aws_rds_cluster_instance.this[*].id
    writer = aws_rds_cluster_instance.this[*].writer
    endpoint = aws_rds_cluster_instance.this[*].endpoint
  }
}