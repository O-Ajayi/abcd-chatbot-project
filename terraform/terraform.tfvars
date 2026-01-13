# AWS Configuration
aws_region   = "us-east-1"
project_name = "chatbot-service"
environment  = "dev"

# VPC Configuration
# Set create_vpc = false to use existing VPC
create_vpc = true
# existing_vpc_id = "vpc-xxxxxxxxx"
# existing_subnet_ids = ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"]

vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

# Security Groups Configuration
# Set create_security_groups = false to use existing security groups
create_security_groups = true
# existing_lambda_security_group_id = "sg-xxxxxxxxx"
# existing_rds_security_group_id = "sg-yyyyyyyyy"
# existing_lex_connect_security_group_id = "sg-zzzzzzzzz"  # Optional
# existing_bedrock_security_group_id = "sg-aaaaaaaaa"  # Optional

# RDS Configuration
# Set create_rds = false to use existing RDS
create_rds = true
# existing_rds_endpoint = "chatbot-db.xxxxxxxxx.us-east-1.rds.amazonaws.com:5432"

rds_instance_class = "db.t3.micro"
rds_engine         = "postgres"
rds_engine_version = "15.4"
rds_database_name  = "chatbotdb"
rds_username       = "chatbotadmin"
rds_password       = "ChangeMe123!" # Change this to a secure password

# Lambda Functions Configuration
create_lambda_functions = true # Set to false to skip Lambda function creation

lambda_functions = [
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

# DynamoDB Tables Configuration
dynamodb_tables = [
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

# Lex Bot Configuration
create_lex_bot = true # Set to false to skip Lex bot creation

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
sqs_max_receive_count = 3

# SNS Configuration
sns_topic_name          = "chatbot-notifications"
sns_subscription_emails = ["your-email@example.com"] # Add your email addresses

# AWS Connect Configuration
create_connect_instance          = true
connect_instance_alias           = "chatbot-connect"
connect_identity_management_type = "CONNECT_MANAGED"

# Bedrock Configuration
create_bedrock_agent     = true
bedrock_agent_name       = "chatbot-agent"
bedrock_foundation_model = "anthropic.claude-3-5-sonnet-20241022-v2:0"

create_kendra_index = true
kendra_index_name   = "chatbot-kendra-index"
kendra_edition      = "DEVELOPER_EDITION"

# CloudWatch Configuration
enable_cloudwatch_alarms  = true
cloudwatch_dashboard_name = "Chatbot-Dashboard"

# Lambda Package Paths (optional - leave null to use placeholder packages)
# After building Lambda functions with ./scripts/build-lambda.sh, uncomment and update:
lambda_package_paths = {
  "chatbot-processor" = "../packages/chatbot-processor.zip"
  "chatbot-analyzer"  = "../packages/chatbot-analyzer.zip"
  "chatbot-reviewer"  = "../packages/chatbot-reviewer.zip"
}

# S3 Configuration
lex_logs_retention_days = 30

# Tags
tags = {
  Project     = "ChatbotService"
  ManagedBy   = "Terraform"
  Environment = "dev"
  Owner       = "DevOps"
  Maintainer  = "HUBDevops@sparksoftcorp.com"
  Support     = "HUBDevops@sparksoftcorp.com, Oluwasegun.Ajayi@sparksoftcorp.com"
}

