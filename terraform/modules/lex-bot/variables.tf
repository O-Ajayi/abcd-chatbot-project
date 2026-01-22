variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "bot_name" {
  description = "Name of the Lex bot"
  type        = string
}

variable "bot_description" {
  description = "Description of the Lex bot"
  type        = string
}

variable "locale_id" {
  description = "Locale ID for Lex bot"
  type        = string
}

variable "sample_intents" {
  description = "Sample intents for Lex bot"
  type = list(object({
    name        = string
    description = string
    utterances  = list(string)
    slots = list(object({
      name                     = string
      slot_type                = string
      value_elicitation_prompt = string
    }))
  }))
}

variable "lambda_function_arn" {
  description = "Lambda function ARN for Lex fulfillment"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "lex_logs_retention_days" {
  description = "Number of days to retain Lex bot logs in S3"
  type        = number
  default     = null
}