variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "env" {
  description = "Environment label"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Prefix for resource names"
  type        = string
  default     = "hub-passthrough"
}

variable "network_mode" {
  description = "Use create to provision VPC/subnets/ALB/EC2, or existing to attach to pre-created network resources"
  type        = string
  default     = "create"

  validation {
    condition     = contains(["create", "existing"], var.network_mode)
    error_message = "network_mode must be either create or existing."
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR block when network_mode is create"
  type        = string
  default     = "10.20.0.0/16"
}

variable "existing_vpc_id" {
  description = "Existing VPC ID when network_mode is existing"
  type        = string
  default     = ""
}

variable "existing_private_subnet_ids" {
  description = "Existing private subnet IDs for VPC link and internal ALB when network_mode is existing"
  type        = list(string)
  default     = []
}

variable "existing_vpc_cidr" {
  description = "Optional VPC CIDR override when network_mode is existing"
  type        = string
  default     = ""
}

variable "existing_alb_listener_arn" {
  description = "Existing ALB listener ARN when network_mode is existing"
  type        = string
  default     = ""
}

variable "existing_alb_security_group_ids" {
  description = "Security group IDs attached to the existing ALB; ingress from the VPC link SG is added automatically"
  type        = list(string)
  default     = []
}

variable "app_port" {
  description = "Port the sample EC2 application listens on"
  type        = number
  default     = 8080
}

variable "instance_type" {
  description = "EC2 instance type for the sample application"
  type        = string
  default     = "t3.micro"
}

variable "api_route_prefix" {
  description = "Route prefix exposed through CloudFront and API Gateway"
  type        = string
  default     = "app"
}
