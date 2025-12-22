
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
  lambda_security_group_id = var.create_vpc ? module.vpc[0].lambda_security_group_id : null
  rds_security_group_id = var.create_vpc ? module.vpc[0].rds_security_group_id : null
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

# DynamoDB Tables
resource "aws_dynamodb_table" "tables" {
  for_each = {
    for idx, table in var.dynamodb_tables : table.name => table
  }

  name           = "${var.project_name}-${each.value.name}"
  billing_mode   = each.value.billing_mode
  hash_key       = each.value.hash_key
  range_key      = each.value.range_key

  dynamic "attribute" {
    for_each = each.value.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  read_capacity  = each.value.billing_mode == "PROVISIONED" ? each.value.read_capacity : null
  write_capacity = each.value.billing_mode == "PROVISIONED" ? each.value.write_capacity : null

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${each.value.name}"
    }
  )
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

  project_name     = var.project_name
  environment      = var.environment
  lambda_functions = var.lambda_functions
  vpc_id           = local.vpc_id
  subnet_ids       = local.subnet_ids
  security_group_ids = local.lambda_security_group_id != null ? [local.lambda_security_group_id] : []
  sqs_queue_arn    = aws_sqs_queue.main.arn
  sqs_queue_url    = aws_sqs_queue.main.url
  dynamodb_tables   = {
    for k, v in aws_dynamodb_table.tables : k => v.arn
  }
  rds_endpoint     = local.rds_endpoint
  sns_topic_arn    = aws_sns_topic.notifications.arn
  tags             = var.tags
}

# Lex Bot Module
module "lex_bot" {
  source = "./modules/lex-bot"

  project_name        = var.project_name
  environment         = var.environment
  bot_name            = var.lex_bot_name
  bot_description     = var.lex_bot_description
  locale_id           = var.lex_bot_locale_id
  sample_intents      = var.lex_sample_intents
  lambda_function_arn = module.lambda_functions.lambda_arns["chatbot-processor"]
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
  lex_bot_arn                   = module.lex_bot.bot_arn
  lambda_function_arns          = module.lambda_functions.lambda_arns
  enable_cloudwatch_alarms      = var.enable_cloudwatch_alarms
  cloudwatch_dashboard_name     = var.cloudwatch_dashboard_name
  sns_topic_arn                 = aws_sns_topic.notifications.arn
  tags                          = var.tags
}

# Bedrock Agent Module
module "bedrock_agent" {
  source = "./modules/bedrock-agent"
  count  = var.create_bedrock_agent ? 1 : 0

  project_name         = var.project_name
  environment          = var.environment
  agent_name           = var.bedrock_agent_name
  foundation_model     = var.bedrock_foundation_model
  create_kendra_index  = var.create_kendra_index
  kendra_index_name    = var.kendra_index_name
  kendra_edition       = var.kendra_edition
  lambda_function_arns = module.lambda_functions.lambda_arns
  dynamodb_table_arns  = {
    for k, v in aws_dynamodb_table.tables : k => v.arn
  }
  tags                 = var.tags
}

