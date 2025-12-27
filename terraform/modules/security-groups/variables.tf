variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "rds_port" {
  description = "RDS port"
  type        = number
  default     = 5432
}

variable "create_lex_connect_sg" {
  description = "Whether to create security group for Lex/Connect"
  type        = bool
  default     = false
}

variable "create_bedrock_sg" {
  description = "Whether to create security group for Bedrock"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

