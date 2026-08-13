module "apigw_passthrough" {
  count  = var.enable_apigw_passthrough ? 1 : 0
  source = "./apigw-passthrough"

  aws_region       = var.aws_region
  env              = var.env
  project_name     = "${var.cdn_name}-passthrough"
  api_route_prefix = var.apigw_passthrough_route_prefix
  network_mode     = var.apigw_passthrough_network_mode
  vpc_cidr         = var.apigw_passthrough_vpc_cidr

  existing_vpc_id             = var.apigw_passthrough_existing_vpc_id
  existing_private_subnet_ids = var.apigw_passthrough_existing_private_subnet_ids
  existing_vpc_cidr           = var.apigw_passthrough_existing_vpc_cidr
}
