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
  value       = { for k, v in module.dynamodb : k => v.dynamodb_table_id }
}

output "dynamodb_table_arns" {
  description = "DynamoDB table ARNs"
  value       = { for k, v in module.dynamodb : k => v.dynamodb_table_arn }
}

output "lambda_function_names" {
  description = "Lambda function names"
  value       = var.create_lambda_functions ? module.lambda_functions[0].lambda_names : {}
}

output "lambda_function_arns" {
  description = "Lambda function ARNs"
  value       = var.create_lambda_functions ? module.lambda_functions[0].lambda_arns : {}
}

output "lex_bot_id" {
  description = "Lex bot ID"
  value       = var.create_lex_bot ? module.lex_bot[0].bot_id : null
}

output "lex_bot_arn" {
  description = "Lex bot ARN"
  value       = var.create_lex_bot ? module.lex_bot[0].bot_arn : null
}

output "lex_bot_alias_id" {
  description = "Lex bot alias ID"
  value       = var.create_lex_bot ? module.lex_bot[0].bot_alias_id : null
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

output "bedrock_agent_id" {
  description = "Bedrock agent ID"
  value       = var.create_bedrock_agent ? module.bedrock_agent[0].agent_id : null
}

output "bedrock_agent_arn" {
  description = "Bedrock agent ARN"
  value       = var.create_bedrock_agent ? module.bedrock_agent[0].agent_arn : null
}

output "bedrock_agent_alias_id" {
  description = "Bedrock agent alias ID"
  value       = var.create_bedrock_agent ? module.bedrock_agent[0].agent_alias_id : null
}

output "bedrock_agent_alias_arn" {
  description = "Bedrock agent alias ARN"
  value       = var.create_bedrock_agent ? module.bedrock_agent[0].agent_alias_arn : null
}

output "bedrock_agent_role_arn" {
  description = "Bedrock agent IAM role ARN"
  value       = var.create_bedrock_agent ? module.bedrock_agent[0].agent_role_arn : null
}

output "bedrock_guardrail_id" {
  description = "Bedrock guardrail ID"
  value       = var.create_bedrock_agent ? module.bedrock_agent[0].guardrail_id : null
}

output "bedrock_guardrail_arn" {
  description = "Bedrock guardrail ARN"
  value       = var.create_bedrock_agent ? module.bedrock_agent[0].guardrail_arn : null
}

output "bedrock_guardrail_version" {
  description = "Bedrock guardrail version"
  value       = var.create_bedrock_agent ? module.bedrock_agent[0].guardrail_version : null
}

output "kendra_index_id" {
  description = "Kendra index ID"
  value       = var.create_bedrock_agent && var.create_kendra_index ? module.bedrock_agent[0].kendra_index_id : null
}

output "kendra_index_arn" {
  description = "Kendra index ARN"
  value       = var.create_bedrock_agent && var.create_kendra_index ? module.bedrock_agent[0].kendra_index_arn : null
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = var.create_connect_instance && var.enable_cloudwatch_alarms ? module.connect[0].dashboard_url : null
}

output "kendra_data_source_bucket_name" {
  description = "S3 bucket name for Kendra data source"
  value       = aws_s3_bucket.kendra_data_source.id
}

output "kendra_data_source_bucket_arn" {
  description = "S3 bucket ARN for Kendra data source"
  value       = aws_s3_bucket.kendra_data_source.arn
}

output "lex_bot_logs_bucket_name" {
  description = "S3 bucket name for Lex bot logs"
  value       = aws_s3_bucket.lex_bot_logs.id
}

output "lex_bot_logs_bucket_arn" {
  description = "S3 bucket ARN for Lex bot logs"
  value       = aws_s3_bucket.lex_bot_logs.arn
}

