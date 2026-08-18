data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_2023" {
  count = local.create_alb ? 1 : 0

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

data "aws_lb" "existing" {
  count = local.use_existing_alb ? 1 : 0
  arn   = var.existing_alb.arn
}

data "aws_lb_listener" "existing" {
  count             = local.use_existing_alb ? 1 : 0
  load_balancer_arn = data.aws_lb.existing[0].arn
  port              = local.existing_alb_listener_port
}

data "aws_vpc" "existing_alb" {
  count = local.use_existing_alb ? 1 : 0
  id    = data.aws_lb.existing[0].vpc_id
}

data "aws_vpc" "configured" {
  count = var.existing_vpc_id != "" ? 1 : 0
  id    = var.existing_vpc_id
}

locals {
  name_prefix = "${var.project_name}-${var.env}"
  azs         = slice(data.aws_availability_zones.available.names, 0, 2)

  use_existing_alb           = var.existing_alb != null
  existing_alb_listener_port = local.use_existing_alb ? coalesce(var.existing_alb.listener_port, 80) : null
  create_alb                 = !local.use_existing_alb
  create_vpc_network         = var.network_mode == "create" && !local.use_existing_alb
  use_existing_network       = var.network_mode == "existing" || local.use_existing_alb
  use_existing_vpc_link_sg   = var.existing_vpc_link_security_group_id != ""

  vpc_id = var.existing_vpc_id != "" ? var.existing_vpc_id : (
    local.use_existing_alb ? data.aws_lb.existing[0].vpc_id : (
      local.create_vpc_network ? aws_vpc.main[0].id : var.existing_vpc_id
    )
  )

  vpc_cidr = var.existing_vpc_cidr != "" ? var.existing_vpc_cidr : (
    local.use_existing_alb ? data.aws_vpc.existing_alb[0].cidr_block : (
      local.create_vpc_network ? var.vpc_cidr : (
        length(data.aws_vpc.configured) > 0 ? data.aws_vpc.configured[0].cidr_block : var.existing_vpc_cidr
      )
    )
  )

  private_subnet_ids = length(var.existing_private_subnet_ids) >= 2 ? var.existing_private_subnet_ids : (
    local.use_existing_alb ? data.aws_lb.existing[0].subnets : (
      local.create_vpc_network ? aws_subnet.private[*].id : var.existing_private_subnet_ids
    )
  )

  vpc_link_security_group_id = local.use_existing_vpc_link_sg ? var.existing_vpc_link_security_group_id : aws_security_group.vpc_link[0].id

  ec2_subnet_id = local.private_subnet_ids[0]

  alb_listener_arn = local.use_existing_alb ? data.aws_lb_listener.existing[0].arn : aws_lb_listener.http[0].arn

  alb_dns_name = local.use_existing_alb ? data.aws_lb.existing[0].dns_name : aws_lb.app[0].dns_name

  existing_alb_security_group_ids = local.use_existing_alb ? data.aws_lb.existing[0].security_groups : []

  public_subnet_cidrs = [
    cidrsubnet(var.vpc_cidr, 8, 1),
    cidrsubnet(var.vpc_cidr, 8, 2),
  ]

  private_subnet_cidrs = [
    cidrsubnet(var.vpc_cidr, 8, 11),
    cidrsubnet(var.vpc_cidr, 8, 12),
  ]
}

check "existing_network_inputs" {
  assert {
    condition = local.use_existing_alb || local.create_vpc_network || (
      var.existing_vpc_id != "" &&
      length(var.existing_private_subnet_ids) >= 2
    )
    error_message = "When network_mode is existing, provide existing_vpc_id and at least two existing_private_subnet_ids."
  }
}

check "existing_alb_inputs" {
  assert {
    condition     = local.create_alb || (var.existing_alb != null && var.existing_alb.arn != "")
    error_message = "When skipping ALB creation, set existing_alb.arn to the internal ALB ARN."
  }
}
