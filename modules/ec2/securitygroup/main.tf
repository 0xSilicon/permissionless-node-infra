variable "name" { type = string }
variable "vpc_id" { type = string }
variable "description" {
  type = string
  default = null
}
variable "ingress" {
  type = list(object({
    from_port = number
    to_port = number
    protocol = string
    cidr_blocks = optional(list(string), [])
    ipv6_cidr_blocks = optional(list(string), [])
    security_groups = optional(list(string), [])
  }))
  default = []
}
variable "egress" {
  type = list(object({
    from_port = number
    to_port = number
    protocol = string
    cidr_blocks = optional(list(string), [])
    ipv6_cidr_blocks = optional(list(string), [])
    security_groups = optional(list(string), [])
  }))
  default = [{
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }]
}

resource "aws_security_group" "this" {
  name = var.name
  description = var.description
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress
    content {
     from_port = lookup(ingress.value, "from_port", null)
     to_port = lookup(ingress.value, "to_port", null)
     protocol = lookup(ingress.value, "protocol", null)
     cidr_blocks = lookup(ingress.value, "cidr_blocks", [])
     ipv6_cidr_blocks = lookup(ingress.value, "ipv6_cidr_blocks", [])
     security_groups = lookup(ingress.value, "security_groups", [])
    }
  }

  dynamic "egress" {
    for_each = var.egress
    content {
     from_port = lookup(egress.value, "from_port", null)
     to_port = lookup(egress.value, "to_port", null)
     protocol = lookup(egress.value, "protocol", null)
     cidr_blocks = lookup(egress.value, "cidr_blocks", [])
     ipv6_cidr_blocks = lookup(egress.value, "ipv6_cidr_blocks", [])
     security_groups = lookup(egress.value, "security_groups", [])
    }
  }

  tags = {
    Name = var.name
  }
}

output "security_group_info" {
  value = {
    id = aws_security_group.this.id
    name = aws_security_group.this.name
  }
}