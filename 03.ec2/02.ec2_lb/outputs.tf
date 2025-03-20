output "lb_info" {
  value = {
    lb_arn      = aws_lb.silicon_lb[0].arn
    lb_dns_name = aws_lb.silicon_lb[0].dns_name
    lb_zone_id  = aws_lb.silicon_lb[0].zone_id
  }
  description = "Information about the Load Balancer (ARN, DNS Name, and Zone ID)"
}

output "tg_info" {
  value = {
    tg_arn      = aws_lb_target_group.silicon_rpc_tg[0].arn
    tg_name     = aws_lb_target_group.silicon_rpc_tg[0].name
    tg_port     = aws_lb_target_group.silicon_rpc_tg[0].port
    tg_protocol = aws_lb_target_group.silicon_rpc_tg[0].protocol
  }
  description = "Information about the Target Group (ARN, Name, Port, Protocol)"
}

output "security_group_info" {
  value = {
    id          = module.load_balancer_sg.security_group_info.id
    name        = module.load_balancer_sg.security_group_info.name
  }
}