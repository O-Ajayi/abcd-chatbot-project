variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "agent_name" {
  description = "Name of the Bedrock agent"
  type        = string
}

variable "foundation_model" {
  description = "Foundation model for Bedrock agent"
  type        = string
}

variable "create_kendra_index" {
  description = "Whether to create Kendra index"
  type        = bool
  default     = true
}

variable "kendra_index_name" {
  description = "Name of the Kendra index"
  type        = string
}

variable "kendra_edition" {
  description = "Kendra edition"
  type        = string
}

variable "lambda_function_arns" {
  description = "Map of Lambda function ARNs"
  type        = map(string)
  default     = {}
}

variable "dynamodb_table_arns" {
  description = "Map of DynamoDB table ARNs"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

