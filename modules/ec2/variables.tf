variable "ami_id" { type = string }
variable "name" { type = string }
variable "instance_type" { type = string }
variable "security_group_ids" { type = list(string) }
variable "subnet_id" { type = string }
variable "user_data" { type = string }
variable "disable_api_termination" { type = bool }
variable "iam_role" { type = string }

variable "block_device_option" {
  type = object({
    size_gib = number
    delete_on_termination = bool
  })
  default = {
    size_gib = 8
    delete_on_termination = true
  }
}