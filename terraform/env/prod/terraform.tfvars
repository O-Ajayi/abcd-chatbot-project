# AWS Configuration - PROD Environment
aws_region   = "us-east-1"
project_name = "chatbot-service"
environment  = "prod"

# VPC Configuration
create_vpc         = true
vpc_cidr           = "10.2.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

# Security Groups Configuration
create_security_groups = true

# RDS Configuration
create_rds         = true
rds_instance_class = "db.t3.medium"
rds_engine         = "postgres"
rds_engine_version = "15.4"
rds_database_name  = "chatbotdb"
rds_username       = "chatbotadmin"
rds_password       = "ChangeMe123!" # Change this to a secure password - USE SECRETS MANAGER IN PROD

# Lambda Functions Configuration
create_lambda_functions = true

lambda_functions = [
  {
    name        = "chatbot-processor"
    description = "Processes chatbot interactions"
    handler     = "index.handler"
    runtime     = "python3.11"
    timeout     = 60
    memory_size = 1024
    environment_variables = {
      ENV = "prod"
    }
  },
  {
    name        = "chatbot-analyzer"
    description = "Analyzes conversation data"
    handler     = "index.handler"
    runtime     = "python3.11"
    timeout     = 120
    memory_size = 2048
    environment_variables = {
      ENV = "prod"
    }
  },
  {
    name        = "chatbot-reviewer"
    description = "Reviews and processes conversation reviews"
    handler     = "index.handler"
    runtime     = "python3.11"
    timeout     = 90
    memory_size = 1024
    environment_variables = {
      ENV = "prod"
    }
  },
  {
    name        = "chatbot-fulfillment"
    description = "Lex intent fulfillment; invokes Bedrock Anthropic Claude 3.5 for responses"
    handler     = "index.handler"
    runtime     = "python3.11"
    timeout     = 30
    memory_size = 256
    environment_variables = {
      ENV                     = "prod"
      USE_BEDROCK_FULFILLMENT = "true"
    }
  }
]

# DynamoDB Tables Configuration
dynamodb_tables = [
  {
    name           = "Chatbot-ConversationHistory"
    hash_key       = "conversation_id"
    range_key      = null
    billing_mode   = "PROVISIONED"
    read_capacity  = 10
    write_capacity = 10
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
    billing_mode   = "PROVISIONED"
    read_capacity  = 5
    write_capacity = 5
    attributes = [
      {
        name = "review_id"
        type = "S"
      }
    ]
  }
]

# Lex Bot Configuration
create_lex_bot      = true
lex_bot_name        = "ChatbotBot"
lex_bot_description = "Chatbot service bot"
lex_bot_locale_id   = "en_US"

lex_sample_intents = [
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
  }
]

# SQS Configuration
sqs_queue_name        = "chatbot-queue"
sqs_dlq_name          = "chatbot-dlq"
sqs_max_receive_count = 5

# SNS Configuration
sns_topic_name          = "chatbot-notifications"
sns_subscription_emails = ["prod-alerts@example.com", "oncall@example.com"]

# AWS Connect Configuration
create_connect_instance          = true
connect_instance_alias           = "chatbot-connect-prod"
connect_identity_management_type = "CONNECT_MANAGED"

# Bedrock Configuration
create_bedrock_agent     = true
bedrock_agent_name       = "chatbot-agent-prod"
bedrock_foundation_model = "anthropic.claude-3-5-sonnet-20241022-v2:0"

create_kendra_index = true
kendra_index_name   = "chatbot-kendra-index-prod"
kendra_edition      = "ENTERPRISE_EDITION"

# CloudWatch Configuration
enable_cloudwatch_alarms  = true
cloudwatch_dashboard_name = "Chatbot-Dashboard-Prod"

# Lambda Package Paths
lambda_package_paths = {
  "chatbot-processor"   = "../packages/chatbot-processor.zip"
  "chatbot-analyzer"   = "../packages/chatbot-analyzer.zip"
  "chatbot-reviewer"   = "../packages/chatbot-reviewer.zip"
  "chatbot-fulfillment" = "../packages/chatbot-fulfillment.zip"
}

# S3 Configuration
lex_logs_retention_days = 90

# Tags
tags = {
  Project     = "ChatbotService"
  ManagedBy   = "Terraform"
  Environment = "prod"
  Owner       = "DevOps"
  Maintainer  = "HUBDevops@sparksoftcorp.com"
  Support     = "HUBDevops@sparksoftcorp.com, Oluwasegun.Ajayi@sparksoftcorp.com"
  CostCenter  = "Engineering"
}

