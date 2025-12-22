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
    name        = string
    description = string
    handler     = string
    runtime     = string
    timeout     = number
    memory_size = number
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

variable "sns_topic_arn" {
  description = "SNS topic ARN"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

