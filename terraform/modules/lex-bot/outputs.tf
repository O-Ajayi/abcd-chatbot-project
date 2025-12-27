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

