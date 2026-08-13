data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

data "aws_vpc" "existing" {
  count = local.use_existing_network ? 1 : 0
  id    = var.existing_vpc_id
}

locals {
  name_prefix = "${var.project_name}-${var.env}"
  azs         = slice(data.aws_availability_zones.available.names, 0, 2)

  create_vpc_network   = var.network_mode == "create"
  use_existing_network = var.network_mode == "existing"

  vpc_id = local.create_vpc_network ? aws_vpc.main[0].id : var.existing_vpc_id

  vpc_cidr = local.create_vpc_network ? var.vpc_cidr : (
    var.existing_vpc_cidr != "" ? var.existing_vpc_cidr : data.aws_vpc.existing[0].cidr_block
  )

  private_subnet_ids = local.create_vpc_network ? aws_subnet.private[*].id : var.existing_private_subnet_ids
  ec2_subnet_id      = local.private_subnet_ids[0]

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
    condition = local.use_existing_network == false || (
      var.existing_vpc_id != "" &&
      length(var.existing_private_subnet_ids) >= 2
    )
    error_message = "When network_mode is existing, set existing_vpc_id and at least two existing_private_subnet_ids."
  }
}
