output "lambda_security_group_id" {
  description = "Lambda security group ID"
  value       = aws_security_group.lambda.id
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

output "lex_connect_security_group_id" {
  description = "Lex/Connect security group ID"
  value       = var.create_lex_connect_sg ? aws_security_group.lex_connect[0].id : null
}

output "bedrock_security_group_id" {
  description = "Bedrock security group ID"
  value       = var.create_bedrock_sg ? aws_security_group.bedrock[0].id : null
}

