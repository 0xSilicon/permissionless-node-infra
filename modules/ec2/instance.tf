resource "aws_instance" "this" {
  ami                     = var.ami_id
  instance_type           = var.instance_type

  vpc_security_group_ids  = var.security_group_ids
  subnet_id               = var.subnet_id
  user_data               = var.user_data
  disable_api_termination = var.disable_api_termination
  iam_instance_profile    = var.iam_role

  root_block_device {
    volume_size           = var.block_device_option.size_gib
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = var.block_device_option.delete_on_termination
    tags = {
      Name = "${var.name}-root"
    }
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = var.name
  }
}