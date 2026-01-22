output "bot_id" {
  description = "Lex bot ID"
  value       = aws_lexv2models_bot.main.id
}

output "bot_arn" {
  description = "Lex bot ARN"
  value       = aws_lexv2models_bot.main.arn
}

# Bot alias output removed - aws_lexv2models_bot_alias resource is not available in AWS provider
# Bot aliases should be created manually via AWS Console or CLI
# output "bot_alias_id" {
#   description = "Lex bot alias ID"
#   value       = aws_lexv2models_bot_alias.main.bot_alias_id
# }

output "bot_version" {
  description = "Lex bot version"
  value       = aws_lexv2models_bot_version.main.bot_version
}

output "lex_bot_logs_bucket_name" {
  description = "S3 bucket name for Lex bot logs"
  value       = aws_s3_bucket.lex_bot_logs.id
}

output "lex_bot_logs_bucket_arn" {
  description = "S3 bucket ARN for Lex bot logs"
  value       = aws_s3_bucket.lex_bot_logs.arn
}

