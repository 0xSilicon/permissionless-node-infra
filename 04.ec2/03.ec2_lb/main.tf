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
  domain   = var.domain_name
  statuses = ["ISSUED"]
}

# Load Balancer 생성
resource "aws_lb" "silicon_lb" {
  count              = 1
  name               = var.lb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.load_balancer_sg.security_group_info.id]
  subnets            = flatten([data.terraform_remote_state.network.outputs.public_subnet_info.id])

  enable_deletion_protection = false
}

# Target Group 생성
resource "aws_lb_target_group" "silicon_rpc_tg" {
  count    = 1
  name     = var.lb_target_group_name
  port     = 443
  protocol = "HTTPS"
  vpc_id = (var.skipNETWORK == true ?
    var.network_object.vpc_id :
    data.terraform_remote_state.network.outputs.vpc_info.vpc_id[0]
  )

  health_check {
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

module "load_balancer_sg" {
  source = "../../modules/ec2/securitygroup"

  name = var.lb_security_group_name
  vpc_id = ( var.skipNETWORK == true ?
    var.network_object.vpc_id :
    data.terraform_remote_state.network.outputs.vpc_info.vpc_id[0]
  )

  # Ingress rules are customized based on requirements
  ingress = (
    fileexists("${path.module}/ip-list.auto.tfvars") && length(var.allowed_ips) > 0 ?
    [
      for ip in var.allowed_ips : {
        description = ip.description
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = [ip.cidr_ip]
      }
    ] :
    [{
      description = "Default HTTPS access"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }]
  )

  egress = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }]
}

resource "aws_lb_listener" "https_listener" {
  count             = length(data.aws_acm_certificate.silicon_cert.arn) == 0 ? 0 : 1
  load_balancer_arn = aws_lb.silicon_lb[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.silicon_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.silicon_rpc_tg[0].arn
  }

  depends_on = [aws_lb.silicon_lb, aws_lb_target_group.silicon_rpc_tg]
}