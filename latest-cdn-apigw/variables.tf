variable "aws_region" {
  default = "us-east-1"
}

variable "bucket_prefix_pvt" {
  default = "gladdd-%s-%s-private"
}

variable "env" {
  default = "dev"
}

variable "cdn_name" {
  default = "hub"
}

variable "access_control" {
  default = "private"
}

variable "enable_apigw_passthrough" {
  description = "Deploy API Gateway passthrough stack to private ALB/EC2 and connect it to CloudFront"
  type        = bool
  default     = true
}

variable "apigw_passthrough_route_prefix" {
  description = "CloudFront/API Gateway path prefix for passthrough routes"
  type        = string
  default     = "app"
}

variable "apigw_passthrough_network_mode" {
  description = "Use create to provision VPC/subnets/NAT plus ALB/EC2, or existing to create only ALB/EC2 in a pre-existing VPC and subnets"
  type        = string
  default     = "create"

  validation {
    condition     = contains(["create", "existing"], var.apigw_passthrough_network_mode)
    error_message = "apigw_passthrough_network_mode must be either create or existing."
  }
}

variable "apigw_passthrough_vpc_cidr" {
  description = "VPC CIDR when apigw_passthrough_network_mode is create"
  type        = string
  default     = "10.20.0.0/16"
}

variable "apigw_passthrough_existing_vpc_id" {
  description = "Existing VPC ID when apigw_passthrough_network_mode is existing"
  type        = string
  default     = ""
}

variable "apigw_passthrough_existing_private_subnet_ids" {
  description = "Existing private subnet IDs for the passthrough VPC link"
  type        = list(string)
  default     = []
}

variable "apigw_passthrough_existing_vpc_cidr" {
  description = "VPC CIDR when apigw_passthrough_network_mode is existing (required)"
  type        = string
  default     = ""
}
