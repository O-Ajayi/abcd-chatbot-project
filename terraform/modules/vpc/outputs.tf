output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "Subnet IDs"
  value       = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

# Security groups are now managed by the security-groups module
# These outputs are kept for backward compatibility
output "lambda_security_group_id" {
  description = "Lambda security group ID (deprecated - use security-groups module)"
  value       = null
}

output "rds_security_group_id" {
  description = "RDS security group ID (deprecated - use security-groups module)"
  value       = null
}

