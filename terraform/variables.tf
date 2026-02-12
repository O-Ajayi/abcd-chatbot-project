variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "chatbot-service"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# VPC Configuration
variable "create_vpc" {
  description = "Whether to create a new VPC or use existing"
  type        = bool
  default     = true
}

variable "existing_vpc_id" {
  description = "Existing VPC ID (required if create_vpc is false)"
  type        = string
  default     = null
}

variable "existing_subnet_ids" {
  description = "Existing subnet IDs (required if create_vpc is false)"
  type        = list(string)
  default     = null
}

variable "vpc_cidr" {
  description = "CIDR block for VPC (used if create_vpc is true)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# Security Groups Configuration
variable "create_security_groups" {
  description = "Whether to create security groups or use existing"
  type        = bool
  default     = true
}

variable "existing_lambda_security_group_id" {
  description = "Existing Lambda security group ID (required if create_security_groups is false)"
  type        = string
  default     = null
}

variable "existing_rds_security_group_id" {
  description = "Existing RDS security group ID (required if create_security_groups is false)"
  type        = string
  default     = null
}

variable "existing_lex_connect_security_group_id" {
  description = "Existing Lex/Connect security group ID (optional)"
  type        = string
  default     = null
}

variable "existing_bedrock_security_group_id" {
  description = "Existing Bedrock security group ID (optional)"
  type        = string
  default     = null
}

# RDS Configuration
variable "create_rds" {
  description = "Whether to create a new RDS instance or use existing"
  type        = bool
  default     = true
}

variable "existing_rds_endpoint" {
  description = "Existing RDS endpoint (required if create_rds is false)"
  type        = string
  default     = null
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_engine" {
  description = "RDS engine (postgres, mysql, etc.)"
  type        = string
  default     = "postgres"
}

variable "rds_engine_version" {
  description = "RDS engine version"
  type        = string
  default     = "15.4"
}

variable "rds_database_name" {
  description = "RDS database name"
  type        = string
  default     = "chatbotdb"
}

variable "rds_username" {
  description = "RDS master username"
  type        = string
  default     = "chatbotadmin"
  sensitive   = true
}

variable "rds_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "lambda_package_paths" {
  description = "Map of Lambda function names to their package file paths (relative to terraform directory). Leave null to use placeholder packages."
  type        = map(string)
  default     = null
  # Example:
  # lambda_package_paths = {
  #   "chatbot-processor" = "../packages/chatbot-processor.zip"
  #   "chatbot-analyzer" = "../packages/chatbot-analyzer.zip"
  #   "chatbot-reviewer" = "../packages/chatbot-reviewer.zip"
  # }
}

# Lambda Functions Configuration
variable "create_lambda_functions" {
  description = "Whether to create Lambda functions"
  type        = bool
  default     = true
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
  default = [
    {
      name        = "chatbot-processor"
      description = "Processes chatbot interactions"
      handler     = "index.handler"
      runtime     = "python3.11"
      timeout     = 30
      memory_size = 256
      environment_variables = {
        ENV = "dev"
      }
    },
    {
      name        = "chatbot-analyzer"
      description = "Analyzes conversation data"
      handler     = "index.handler"
      runtime     = "python3.11"
      timeout     = 60
      memory_size = 512
      environment_variables = {
        ENV = "dev"
      }
    },
    {
      name        = "chatbot-reviewer"
      description = "Reviews and processes conversation reviews"
      handler     = "index.handler"
      runtime     = "python3.11"
      timeout     = 45
      memory_size = 256
      environment_variables = {
        ENV = "dev"
      }
    }
  ]
}

# DynamoDB Tables Configuration
variable "dynamodb_tables" {
  description = "List of DynamoDB table configurations"
  type = list(object({
    name           = string
    hash_key       = string
    range_key      = string
    billing_mode   = string
    read_capacity  = number
    write_capacity = number
    attributes = list(object({
      name = string
      type = string
    }))
  }))
  default = [
    {
      name           = "Chatbot-ConversationHistory"
      hash_key       = "conversation_id"
      range_key      = null
      billing_mode   = "PAY_PER_REQUEST"
      read_capacity  = null
      write_capacity = null
      attributes = [
        {
          name = "conversation_id"
          type = "S"
        }
      ]
    },
    {
      name           = "Chatbot-Conversation-Reviewer"
      hash_key       = "review_id"
      range_key      = null
      billing_mode   = "PAY_PER_REQUEST"
      read_capacity  = null
      write_capacity = null
      attributes = [
        {
          name = "review_id"
          type = "S"
        }
      ]
    }
  ]
}

# Lex Bot Configuration
variable "create_lex_bot" {
  description = "Whether to create Lex bot"
  type        = bool
  default     = true
}

variable "lex_bot_name" {
  description = "Name of the Lex bot"
  type        = string
  default     = "ChatbotBot"
}

variable "lex_bot_description" {
  description = "Description of the Lex bot"
  type        = string
  default     = "Chatbot service bot"
}

variable "lex_bot_locale_id" {
  description = "Locale ID for Lex bot"
  type        = string
  default     = "en_US"
}

variable "lex_sample_intents" {
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
  default = [
    {
      name        = "GreetingIntent"
      description = "Handles greeting messages"
      utterances  = ["Hello", "Hi", "Hey", "Good morning", "Good afternoon"]
      slots       = []
    },
    {
      name        = "HelpIntent"
      description = "Handles help requests"
      utterances  = ["I need help", "Can you help me", "Help", "What can you do"]
      slots       = []
    },
    {
      name        = "GoodbyeIntent"
      description = "Handles goodbye messages"
      utterances  = ["Goodbye", "Bye", "See you later", "Thanks"]
      slots       = []
    },
    {
      name        = "FallbackIntent"
      description = "Catches unrecognized input; fulfillment Lambda sends to Bedrock for response"
      utterances  = []
      slots       = []
    }
  ]
}

# SQS Configuration
variable "sqs_queue_name" {
  description = "Name of the SQS queue"
  type        = string
  default     = "chatbot-queue"
}

variable "sqs_dlq_name" {
  description = "Name of the SQS dead letter queue"
  type        = string
  default     = "chatbot-dlq"
}

variable "sqs_max_receive_count" {
  description = "Maximum receive count for DLQ"
  type        = number
  default     = 3
}

# SNS Configuration
variable "sns_topic_name" {
  description = "Name of the SNS topic"
  type        = string
  default     = "chatbot-notifications"
}

variable "sns_subscription_emails" {
  description = "List of email addresses for SNS subscriptions"
  type        = list(string)
  default     = []
}

# AWS Connect Configuration
variable "create_connect_instance" {
  description = "Whether to create AWS Connect instance"
  type        = bool
  default     = true
}

variable "connect_instance_alias" {
  description = "Alias for AWS Connect instance"
  type        = string
  default     = "chatbot-connect"
}

variable "connect_identity_management_type" {
  description = "Identity management type for Connect"
  type        = string
  default     = "CONNECT_MANAGED"
}

# Bedrock Configuration
variable "create_bedrock_agent" {
  description = "Whether to create Bedrock agent"
  type        = bool
  default     = true
}

variable "create_default_kb" {
  description = "Whether to create the default OpenSearch-based knowledge base"
  type        = bool
  default     = false
}

variable "bedrock_agent_name" {
  description = "Name of the Bedrock agent"
  type        = string
  default     = "chatbot-agent"
}

variable "bedrock_foundation_model" {
  description = "Foundation model for Bedrock agent"
  type        = string
  default     = "anthropic.claude-3-5-sonnet-20241022-v2:0"
}

variable "bedrock_fulfillment_model_id" {
  description = "Inference profile ID or ARN for the fulfillment Lambda (passed as BEDROCK_INFERENCE_PROFILE_ARN). Required in many regions; create in Bedrock console → Inference → Application inference profiles. Leave null to use Lambda default (BEDROCK_MODEL_ID)."
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
  default     = "chatbot-kendra-index"
}

variable "kendra_edition" {
  description = "Kendra edition (DEVELOPER_EDITION or ENTERPRISE_EDITION)"
  type        = string
  default     = "DEVELOPER_EDITION"
}

variable "opensearch_url" {
  description = "OpenSearch endpoint URL for the opensearch provider"
  type        = string
  default     = "http://localhost:9200"
}

# CloudWatch Configuration
variable "enable_cloudwatch_alarms" {
  description = "Whether to enable CloudWatch alarms"
  type        = bool
  default     = true
}

variable "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  type        = string
  default     = "Chatbot-Dashboard"
}

# S3 Configuration
variable "lex_logs_retention_days" {
  description = "Number of days to retain Lex bot logs in S3"
  type        = number
  default     = 30
}

# Tags
variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "ChatbotService"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}

