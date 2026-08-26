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

variable "create_cdn" {
  description = "When true, create the S3 bucket and CloudFront distribution. When false, use existing_cloudfront_domain_name."
  type        = bool
  default     = true
}

variable "existing_cloudfront_domain_name" {
  description = "Existing CloudFront distribution domain name when create_cdn is false (e.g. d1234abcd.cloudfront.net)"
  type        = string
  default     = ""
}

variable "existing_cloudfront_distribution_id" {
  description = "Existing CloudFront distribution ID when create_cdn is false (reference only)"
  type        = string
  default     = ""
}

variable "enable_apigw_passthrough" {
  description = "Deploy API Gateway passthrough stack to private ALB/EC2 and connect it to CloudFront"
  type        = bool
  default     = true
}

variable "apigw_passthrough_route_prefix" {
  description = "CloudFront path prefix for API Gateway passthrough (e.g. api -> /api/*). Leave empty to serve only S3 from CloudFront. API Gateway direct URL always forwards any route to the ALB."
  type        = string
  default     = ""
}

variable "apigw_passthrough_network_mode" {
  description = "Use create to provision VPC/subnets/NAT plus ALB/EC2, or existing to reuse VPC/subnets and skip network creation"
  type        = string
  default     = "existing"

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

variable "apigw_passthrough_existing_alb_arn" {
  description = "Existing internal ALB ARN. When set, skips creating ALB, target group, and EC2 instance."
  type        = string
  default     = ""
}

variable "apigw_passthrough_existing_alb_listener_port" {
  description = "Listener port on the existing ALB used for the API Gateway integration"
  type        = number
  default     = 80
}

variable "apigw_passthrough_existing_vpc_link_security_group_id" {
  description = "Existing security group for API Gateway VPC link ENIs. When set, skips creating a new VPC link security group."
  type        = string
  default     = ""
}
