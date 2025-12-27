
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      var.tags,
      {
        Environment = var.environment
        Project     = var.project_name
      }
    )
  }
}

# Data sources for existing resources
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  count  = var.create_vpc ? 1 : 0

  project_name     = var.project_name
  environment      = var.environment
  vpc_cidr         = var.vpc_cidr
  availability_zones = var.availability_zones
  tags             = var.tags
}

# Use existing VPC if not creating new one
locals {
  vpc_id = var.create_vpc ? module.vpc[0].vpc_id : var.existing_vpc_id
  subnet_ids = var.create_vpc ? module.vpc[0].subnet_ids : var.existing_subnet_ids
}

# RDS Module
module "rds" {
  source = "./modules/rds"
  count  = var.create_rds ? 1 : 0

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = local.vpc_id
  subnet_ids        = local.subnet_ids
  instance_class    = var.rds_instance_class
  engine            = var.rds_engine
  engine_version    = var.rds_engine_version
  database_name     = var.rds_database_name
  master_username   = var.rds_username
  master_password   = var.rds_password
  security_group_id = local.rds_security_group_id
  tags              = var.tags
}

locals {
  rds_endpoint = var.create_rds ? module.rds[0].rds_endpoint : var.existing_rds_endpoint
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security-groups"
  count  = var.create_security_groups ? 1 : 0

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = local.vpc_id
  rds_port              = var.rds_engine == "postgres" ? 5432 : 3306
  create_lex_connect_sg = var.create_lex_bot || var.create_connect_instance
  create_bedrock_sg     = var.create_bedrock_agent
  tags                  = var.tags
}

# Use existing security groups if not creating new ones
locals {
  lambda_security_group_id = var.create_security_groups ? module.security_groups[0].lambda_security_group_id : var.existing_lambda_security_group_id
  rds_security_group_id   = var.create_security_groups ? module.security_groups[0].rds_security_group_id : var.existing_rds_security_group_id
  lex_connect_security_group_id = var.create_security_groups ? module.security_groups[0].lex_connect_security_group_id : var.existing_lex_connect_security_group_id
  bedrock_security_group_id     = var.create_security_groups ? module.security_groups[0].bedrock_security_group_id : var.existing_bedrock_security_group_id
}

# DynamoDB Tables Module
module "dynamodb" {
  source = "./modules/dynamodb"

  project_name = var.project_name
  tables       = var.dynamodb_tables
  tags         = var.tags
}

# S3 Bucket for Kendra Data Source
resource "aws_s3_bucket" "kendra_data_source" {
  bucket = "${var.project_name}-${var.environment}-kendra-data-source"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-kendra-data-source"
      Purpose = "KendraDataSource"
    }
  )
}

resource "aws_s3_bucket_versioning" "kendra_data_source" {
  bucket = aws_s3_bucket.kendra_data_source.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "kendra_data_source" {
  bucket = aws_s3_bucket.kendra_data_source.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "kendra_data_source" {
  bucket = aws_s3_bucket.kendra_data_source.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket for Lex Bot Logs
resource "aws_s3_bucket" "lex_bot_logs" {
  bucket = "${var.project_name}-${var.environment}-lex-bot-logs"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-lex-bot-logs"
      Purpose = "LexBotLogs"
    }
  )
}

resource "aws_s3_bucket_versioning" "lex_bot_logs" {
  bucket = aws_s3_bucket.lex_bot_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lex_bot_logs" {
  bucket = aws_s3_bucket.lex_bot_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "lex_bot_logs" {
  bucket = aws_s3_bucket.lex_bot_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "lex_bot_logs" {
  bucket = aws_s3_bucket.lex_bot_logs.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = var.lex_logs_retention_days
    }
  }
}

# SNS Topic
resource "aws_sns_topic" "notifications" {
  name = "${var.project_name}-${var.sns_topic_name}"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.sns_topic_name}"
    }
  )
}

# SNS Email Subscriptions
resource "aws_sns_topic_subscription" "email" {
  for_each = toset(var.sns_subscription_emails)

  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "email"
  endpoint  = each.value
}

# SQS Queue
resource "aws_sqs_queue" "main" {
  name                       = "${var.project_name}-${var.sqs_queue_name}"
  visibility_timeout_seconds = 300
  message_retention_seconds  = 345600 # 4 days
  receive_wait_time_seconds  = 20

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.sqs_queue_name}"
    }
  )
}

# SQS Dead Letter Queue
resource "aws_sqs_queue" "dlq" {
  name = "${var.project_name}-${var.sqs_dlq_name}"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.sqs_dlq_name}"
    }
  )
}

# SQS Redrive Policy
resource "aws_sqs_queue_redrive_policy" "main" {
  queue_url = aws_sqs_queue.main.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.sqs_max_receive_count
  })
}

# Lambda Functions Module
module "lambda_functions" {
  source = "./modules/lambda-functions"
  count  = var.create_lambda_functions ? 1 : 0

  project_name     = var.project_name
  environment      = var.environment
  lambda_functions = var.lambda_functions
  vpc_id           = local.vpc_id
  subnet_ids       = local.subnet_ids
  security_group_ids = local.lambda_security_group_id != null ? [local.lambda_security_group_id] : []
  sqs_queue_arn         = aws_sqs_queue.main.arn
  sqs_queue_url         = aws_sqs_queue.main.url
  dynamodb_tables       = module.dynamodb.table_arns
  dynamodb_table_names  = module.dynamodb.table_names
  rds_endpoint          = local.rds_endpoint
  rds_username          = var.rds_username
  rds_password          = var.rds_password
  rds_database_name     = var.rds_database_name
  kendra_data_source_bucket = aws_s3_bucket.kendra_data_source.id
  lex_bot_logs_bucket   = aws_s3_bucket.lex_bot_logs.id
  lambda_package_paths  = var.lambda_package_paths
  sns_topic_arn         = aws_sns_topic.notifications.arn
  tags                  = var.tags
}

# Lex Bot Module
module "lex_bot" {
  source = "./modules/lex-bot"
  count  = var.create_lex_bot ? 1 : 0

  project_name        = var.project_name
  environment         = var.environment
  bot_name            = var.lex_bot_name
  bot_description     = var.lex_bot_description
  locale_id           = var.lex_bot_locale_id
  sample_intents      = var.lex_sample_intents
  lambda_function_arn = var.create_lambda_functions ? module.lambda_functions[0].lambda_arns["chatbot-processor"] : null
  tags                = var.tags
}

# AWS Connect Module
module "connect" {
  source = "./modules/connect"
  count  = var.create_connect_instance ? 1 : 0

  project_name                  = var.project_name
  environment                   = var.environment
  instance_alias                = var.connect_instance_alias
  identity_management_type      = var.connect_identity_management_type
  lex_bot_arn                   = var.create_lex_bot ? module.lex_bot[0].bot_arn : null
  lambda_function_arns          = var.create_lambda_functions ? module.lambda_functions[0].lambda_arns : {}
  enable_cloudwatch_alarms      = var.enable_cloudwatch_alarms
  cloudwatch_dashboard_name     = var.cloudwatch_dashboard_name
  sns_topic_arn                 = aws_sns_topic.notifications.arn
  tags                          = var.tags
}

# Bedrock Agent Module (using local module)
module "bedrock_agent" {
  source = "./modules/bedrock-agent"
  count  = var.create_bedrock_agent ? 1 : 0

  project_name         = var.project_name
  environment          = var.environment
  agent_name           = var.bedrock_agent_name
  foundation_model     = var.bedrock_foundation_model
  instruction          = "You are a helpful chatbot assistant. Use the provided knowledge base and tools to answer questions accurately. Provide clear and concise responses to user queries."
  agent_description    = "Chatbot agent for ${var.project_name}"
  idle_session_ttl     = 1800
  create_kendra_index = var.create_kendra_index
  kendra_index_name    = var.kendra_index_name
  kendra_edition      = var.kendra_edition
  create_knowledge_base = var.create_kendra_index
  kb_s3_data_source    = var.create_kendra_index ? aws_s3_bucket.kendra_data_source.arn : null
  lambda_function_arns = var.create_lambda_functions ? module.lambda_functions[0].lambda_arns : {}
  dynamodb_table_arns  = module.dynamodb.table_arns
  tags                 = var.tags
}

