output "agent_role_arn" {
  description = "IAM role ARN for Bedrock agent (use this when creating the agent manually or via module)"
  value       = aws_iam_role.bedrock_agent.arn
}

output "agent_id" {
  description = "Bedrock agent ID (placeholder - agent must be created manually or via module)"
  value       = null
}

output "agent_arn" {
  description = "Bedrock agent ARN (placeholder - agent must be created manually or via module)"
  value       = null
}

output "kendra_index_id" {
  description = "Kendra index ID"
  value       = var.create_kendra_index ? aws_kendra_index.main[0].id : null
}

output "kendra_index_arn" {
  description = "Kendra index ARN"
  value       = var.create_kendra_index ? aws_kendra_index.main[0].arn : null
}

