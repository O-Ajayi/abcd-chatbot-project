output "agent_role_arn" {
  description = "IAM role ARN for Bedrock agent"
  value       = aws_iam_role.bedrock_agent.arn
}

output "kendra_role_arn" {
  description = "IAM role ARN for Kendra (if created)"
  value       = var.create_kendra_index ? aws_iam_role.kendra[0].arn : null
}

output "agent_id" {
  description = "Bedrock agent ID"
  value       = aws_bedrock_agent.main.agent_id
}

output "agent_arn" {
  description = "Bedrock agent ARN"
  value       = aws_bedrock_agent.main.agent_arn
}

output "agent_alias_id" {
  description = "Bedrock agent alias ID"
  value       = aws_bedrock_agent_alias.main.agent_alias_id
}

output "agent_alias_arn" {
  description = "Bedrock agent alias ARN"
  value       = aws_bedrock_agent_alias.main.agent_alias_arn
}

output "kendra_index_id" {
  description = "Kendra index ID (if created)"
  value       = var.create_kendra_index ? aws_kendra_index.main[0].id : null
}

output "kendra_index_arn" {
  description = "Kendra index ARN (if created)"
  value       = var.create_kendra_index ? aws_kendra_index.main[0].arn : null
}

output "knowledge_base_id" {
  description = "Bedrock Knowledge Base ID (if created)"
  value       = var.create_kendra_index && var.create_knowledge_base ? aws_bedrock_knowledge_base.main[0].knowledge_base_id : null
}

