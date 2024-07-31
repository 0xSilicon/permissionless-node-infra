data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64*"]
  }

  owners = ["amazon"]
}

data "aws_ami" "ubuntu_arm64" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64*"]
  }

  owners = ["amazon"]
}

data "aws_ami" "amazon_linux2" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  owners = ["amazon"]
}

locals {
  ami_data = {
    ubuntu = data.aws_ami.ubuntu
    ubuntu_arm64 = data.aws_ami.ubuntu_arm64
    amazon_linux2 = data.aws_ami.amazon_linux2
  }
}

output "object" {
  value = local.ami_data
}