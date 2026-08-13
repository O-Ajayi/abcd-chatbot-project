# Passthrough stack defaults (create mode)
aws_region = "us-east-1"
env        = "dev"
cdn_name   = "hub"

enable_apigw_passthrough = true
# apigw_passthrough_network_mode = "create"
# apigw_passthrough_vpc_cidr = "10.20.0.0/16"

# Existing network mode: reuse VPC/subnets, create ALB + EC2 + API Gateway only
apigw_passthrough_network_mode                = "existing"
apigw_passthrough_existing_vpc_id             = "vpc-030d0ffee8ff73090"
apigw_passthrough_existing_private_subnet_ids = ["subnet-084ed017404954f09", "subnet-06b8465757eabf63f"]
apigw_passthrough_existing_vpc_cidr           = "172.31.0.0/16"
