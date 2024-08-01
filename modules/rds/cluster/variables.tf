variable "name" { type = string }
variable "engine" { type = string }
variable "engine_version" { type = string }
variable "port" { type = number }
variable "instance_class" { type = string }
variable "instance_count" { type = number }

variable "database_name" { type = string }
variable "master_username" { type = string }
variable "master_password" { type = string }
variable "backup_retention_period" { type = number }
variable "deletion_protection" { type = bool }
variable "skip_final_snapshot" { type = bool }
variable "pg_family" { type = string }

variable "vpc_id" { type = string }
variable "vpc_cidr" { type = string }
variable "availability_zones" { type = list(string) }
variable "db_subnet_group_name" { type = string }

variable "iam_role_info" {
  type = object({
    name = string,
    arn = string,
  })
}

variable "final_snapshot_identifier" {
  type = string
  default = "final-snapshot"
}