variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "lambda_functions" {
  description = "List of Lambda function configurations"
  type = list(object({
    name                  = string
    description           = string
    handler               = string
    runtime               = string
    timeout               = number
    memory_size           = number
    environment_variables = map(string)
  }))
}

variable "vpc_id" {
  description = "VPC ID for Lambda functions"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs for Lambda functions"
  type        = list(string)
  default     = null
}

variable "security_group_ids" {
  description = "Security group IDs for Lambda functions"
  type        = list(string)
  default     = null
}

variable "sqs_queue_arn" {
  description = "SQS queue ARN"
  type        = string
}

variable "sqs_queue_url" {
  description = "SQS queue URL"
  type        = string
  default     = ""
}

variable "dynamodb_tables" {
  description = "Map of DynamoDB table ARNs"
  type        = map(string)
  default     = {}
}

variable "rds_endpoint" {
  description = "RDS endpoint"
  type        = string
  default     = ""
}

variable "rds_username" {
  description = "RDS username"
  type        = string
  default     = ""
  sensitive   = true
}

variable "rds_password" {
  description = "RDS password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "rds_database_name" {
  description = "RDS database name"
  type        = string
  default     = ""
}

variable "dynamodb_table_names" {
  description = "Map of DynamoDB table names"
  type        = map(string)
  default     = null
}

variable "kendra_data_source_bucket" {
  description = "S3 bucket name for Kendra data source"
  type        = string
  default     = ""
}

variable "lex_bot_logs_bucket" {
  description = "S3 bucket name for Lex bot logs"
  type        = string
  default     = ""
}

variable "lambda_package_paths" {
  description = "Map of Lambda function names to their package file paths (relative to module)"
  type        = map(string)
  default     = null
}

variable "sns_topic_arn" {
  description = "SNS topic ARN"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

