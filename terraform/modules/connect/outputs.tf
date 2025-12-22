output "instance_id" {
  description = "AWS Connect instance ID"
  value       = aws_connect_instance.main.id
}

output "instance_arn" {
  description = "AWS Connect instance ARN"
  value       = aws_connect_instance.main.arn
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = var.enable_cloudwatch_alarms ? "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${var.cloudwatch_dashboard_name}" : null
}

data "aws_region" "current" {}

