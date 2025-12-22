output "bot_id" {
  description = "Lex bot ID"
  value       = aws_lexv2models_bot.main.id
}

output "bot_arn" {
  description = "Lex bot ARN"
  value       = aws_lexv2models_bot.main.arn
}

output "bot_alias_id" {
  description = "Lex bot alias ID"
  value       = aws_lexv2models_bot_alias.main.bot_alias_id
}

output "bot_version" {
  description = "Lex bot version"
  value       = aws_lexv2models_bot_version.main.bot_version
}

