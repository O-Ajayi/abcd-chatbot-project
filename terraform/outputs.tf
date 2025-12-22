output "vpc_id" {
  description = "VPC ID"
  value       = local.vpc_id
}

output "subnet_ids" {
  description = "Subnet IDs"
  value       = local.subnet_ids
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = local.rds_endpoint
  sensitive   = true
}

output "dynamodb_table_names" {
  description = "DynamoDB table names"
  value = {
    for k, v in aws_dynamodb_table.tables : k => v.name
  }
}

output "dynamodb_table_arns" {
  description = "DynamoDB table ARNs"
  value = {
    for k, v in aws_dynamodb_table.tables : k => v.arn
  }
}

output "lambda_function_names" {
  description = "Lambda function names"
  value       = module.lambda_functions.lambda_names
}

output "lambda_function_arns" {
  description = "Lambda function ARNs"
  value       = module.lambda_functions.lambda_arns
}

output "lex_bot_id" {
  description = "Lex bot ID"
  value       = module.lex_bot.bot_id
}

output "lex_bot_arn" {
  description = "Lex bot ARN"
  value       = module.lex_bot.bot_arn
}

output "lex_bot_alias_id" {
  description = "Lex bot alias ID"
  value       = module.lex_bot.bot_alias_id
}

output "sqs_queue_url" {
  description = "SQS queue URL"
  value       = aws_sqs_queue.main.url
}

output "sqs_queue_arn" {
  description = "SQS queue ARN"
  value       = aws_sqs_queue.main.arn
}

output "sns_topic_arn" {
  description = "SNS topic ARN"
  value       = aws_sns_topic.notifications.arn
}

output "connect_instance_id" {
  description = "AWS Connect instance ID"
  value       = var.create_connect_instance ? module.connect[0].instance_id : null
}

output "connect_instance_arn" {
  description = "AWS Connect instance ARN"
  value       = var.create_connect_instance ? module.connect[0].instance_arn : null
}

output "bedrock_agent_role_arn" {
  description = "Bedrock agent IAM role ARN (use this when creating the agent)"
  value       = var.create_bedrock_agent ? module.bedrock_agent[0].agent_role_arn : null
}

output "bedrock_agent_id" {
  description = "Bedrock agent ID (create agent manually or via module)"
  value       = null
}

output "bedrock_agent_arn" {
  description = "Bedrock agent ARN (create agent manually or via module)"
  value       = null
}

output "kendra_index_id" {
  description = "Kendra index ID"
  value       = var.create_bedrock_agent && var.create_kendra_index ? module.bedrock_agent[0].kendra_index_id : null
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = var.create_connect_instance && var.enable_cloudwatch_alarms ? module.connect[0].dashboard_url : null
}

