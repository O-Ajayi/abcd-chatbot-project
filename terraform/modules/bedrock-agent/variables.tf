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

variable "instruction" {
  description = "Instructions for the Bedrock agent"
  type        = string
  default     = null
}

variable "agent_description" {
  description = "Description of the Bedrock agent"
  type        = string
  default     = null
}

variable "idle_session_ttl" {
  description = "Idle session TTL in seconds"
  type        = number
  default     = null
}

variable "prompt_override_configuration" {
  description = "Prompt override configuration for the agent"
  type = object({
    base_prompt_template = string
    inference_configuration = object({
      max_tokens  = optional(number)
      temperature = optional(number)
      top_p       = optional(number)
      top_k       = optional(number)
    })
  })
  default = null
}

variable "create_knowledge_base" {
  description = "Whether to create Bedrock Knowledge Base"
  type        = bool
  default     = false
}

variable "kb_s3_data_source" {
  description = "S3 bucket ARN for Knowledge Base data source"
  type        = string
  default     = null
}

variable "embedding_model_arn" {
  description = "ARN of the embedding model for Knowledge Base"
  type        = string
  default     = null
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

