# ---------------------------------------------------------------------------
# Active config: API Gateway + VPC link only (CDN deferred, no new VPC/network)
# Creates: HTTP API, Lambda authorizer, VPC link
# Reuses:  existing VPC, subnets, ALB, VPC link security group
# Skips:   CDN/S3, VPC/subnets/NAT, ALB, target group, EC2
# ---------------------------------------------------------------------------
aws_region = "us-east-1"
env        = "dev"
cdn_name   = "hub"

create_cdn               = true
enable_apigw_passthrough = true

# CDN root (/) serves S3 index.html. Backend passthrough via CloudFront uses /api/*
apigw_passthrough_route_prefix = "api"

apigw_passthrough_network_mode                = "existing"
apigw_passthrough_existing_vpc_id             = "vpc-050a7a633cf4012cc"
apigw_passthrough_existing_private_subnet_ids = ["subnet-05896f880410b7a85", "subnet-0718c201344a7c04e"]
apigw_passthrough_existing_vpc_cidr           = "172.31.0.0/16"

apigw_passthrough_existing_alb_arn                    = "arn:aws:elasticloadbalancing:us-east-1:518761466634:loadbalancer/app/my-demo-alb/f8c504ad5b1522a9"
apigw_passthrough_existing_alb_listener_port          = 80
apigw_passthrough_existing_vpc_link_security_group_id = "sg-0ac5361c6954d0365" # replace with your VPC link SG

# After apply, use output apigw_passthrough_cloudfront_origin_config when create_cdn = true

# ---------------------------------------------------------------------------
# Mode 1: Create everything (CDN + VPC + ALB + EC2 + API Gateway)
# ---------------------------------------------------------------------------
# create_cdn                     = true
# enable_apigw_passthrough       = true
# apigw_passthrough_network_mode = "create"
# apigw_passthrough_vpc_cidr     = "10.20.0.0/16"

# ---------------------------------------------------------------------------
# Mode 2: Create CDN + API Gateway, reuse existing VPC, create ALB/EC2
# ---------------------------------------------------------------------------
# create_cdn               = true
# enable_apigw_passthrough = true
# apigw_passthrough_network_mode                = "existing"
# apigw_passthrough_existing_vpc_id             = "vpc-..."
# apigw_passthrough_existing_private_subnet_ids = ["subnet-...", "subnet-..."]
# apigw_passthrough_existing_vpc_cidr           = "172.31.0.0/16"

# ---------------------------------------------------------------------------
# Mode 3: Reuse existing CDN + existing ALB
# ---------------------------------------------------------------------------
# create_cdn                          = false
# existing_cloudfront_domain_name     = "d1234abcd.cloudfront.net"
# existing_cloudfront_distribution_id = "E1234ABCD"
