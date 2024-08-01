resource "aws_rds_cluster" "this" {
  cluster_identifier              = var.name
  engine                          = var.engine
  engine_version                  = var.engine_version
  availability_zones              = var.availability_zones
  database_name                   = var.database_name
  master_username                 = var.master_username
  master_password                 = var.master_password
  backup_retention_period         = var.backup_retention_period
  deletion_protection             = var.deletion_protection
  vpc_security_group_ids          = [ aws_security_group.this.id ]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.name
  db_subnet_group_name            = var.db_subnet_group_name
  skip_final_snapshot             = var.skip_final_snapshot
  final_snapshot_identifier       = var.final_snapshot_identifier
  preferred_backup_window         = "17:00-17:30"
  preferred_maintenance_window    = "sun:18:00-sun:18:30"
}

resource "aws_rds_cluster_instance" "this" {
  count                        = var.instance_count
  identifier                   = "${var.name}-${count.index}"
  cluster_identifier           = aws_rds_cluster.this.id
  instance_class               = var.instance_class
  engine                       = aws_rds_cluster.this.engine
  engine_version               = aws_rds_cluster.this.engine_version
  auto_minor_version_upgrade   = false
  preferred_maintenance_window = "sun:18:00-sun:18:30"
}

resource "aws_rds_cluster_parameter_group" "this" {
  name        = "${var.name}-pg"
  family      = var.pg_family
  description = "${var.name} db cluster parameter group"

  parameter {
    name  = "rds.force_ssl"
    value = 0
  }
}

resource "aws_rds_cluster_role_association" "this" {
    db_cluster_identifier = aws_rds_cluster.this.id
    feature_name = "Comprehend"
    role_arn = var.iam_role_info.arn
}

resource "aws_security_group" "this" {
  name   = "${var.name}-rds-sg"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "TCP"
    cidr_blocks = [var.vpc_cidr]
  }
}