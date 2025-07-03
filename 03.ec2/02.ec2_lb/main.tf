data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.s3_bucket
    key    = var.s3_tfstate_network
    region = var.aws_region
    profile = var.aws_profile_name
  }
}

data "aws_acm_certificate" "silicon_cert" {
  count    = var.domain_name != "" ? 1 : 0
  domain   = var.domain_name
  statuses = ["ISSUED"]
}

# Load Balancer 생성
resource "aws_lb" "silicon_lb" {
  count              = 1
  name               = "silicon-${var.nameOfL1}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.load_balancer_sg.security_group_info.id]
  subnets            = flatten([data.terraform_remote_state.network.outputs.public_subnet_info.id])

  enable_deletion_protection = false
}

# Target Group 생성
resource "aws_lb_target_group" "silicon_rpc_tg" {
  count    = 1
  name     = "silicon-${var.nameOfL1}-tg"
  port     = 8545
  protocol = "HTTP"
  vpc_id = (var.skipNETWORK == true ?
    var.network_object.vpc_id :
    data.terraform_remote_state.network.outputs.vpc_info.vpc_id[0]
  )

  health_check {
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

module "load_balancer_sg" {
  source = "../../modules/ec2/securitygroup"

  name = "silicon-${var.nameOfL1}-public-sg"
  vpc_id = (
    var.skipNETWORK == true ?
    var.network_object.vpc_id :
    data.terraform_remote_state.network.outputs.vpc_info.vpc_id[0]
  )

  ingress = [
    {
      description = "Secure RPC access"
      from_port   = 8545
      to_port     = 8545
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  egress = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }]
}

# Create HTTP listener (if no domain name is provided)
resource "aws_lb_listener" "http_listener" {
  count             = var.domain_name == "" ? 1 : 0
  load_balancer_arn = aws_lb.silicon_lb[0].arn
  port              = 8545
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.silicon_rpc_tg[0].arn
  }

  depends_on = [aws_lb.silicon_lb, aws_lb_target_group.silicon_rpc_tg]
}

# Create HTTPS listener (if a domain name is provided and certificate is available)
resource "aws_lb_listener" "https_listener" {
  count             = var.domain_name != "" ? 1 : 0
  load_balancer_arn = aws_lb.silicon_lb[0].arn
  port              = 8545
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.silicon_cert[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.silicon_rpc_tg[0].arn
  }

  depends_on = [aws_lb.silicon_lb, aws_lb_target_group.silicon_rpc_tg]
}
