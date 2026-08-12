output "api_id" {
  description = "HTTP API Gateway ID for CloudFront origin"
  value       = aws_apigatewayv2_api.passthrough.id
}

output "api_endpoint" {
  description = "API Gateway invoke URL"
  value       = aws_apigatewayv2_stage.prod.invoke_url
}

output "api_stage_name" {
  description = "API Gateway stage name"
  value       = aws_apigatewayv2_stage.prod.name
}

output "api_route_prefix" {
  description = "Route prefix routed through CloudFront"
  value       = var.api_route_prefix
}

output "cloudfront_origin_domain" {
  description = "Domain name for CloudFront custom origin"
  value       = "${aws_apigatewayv2_api.passthrough.id}.execute-api.${var.aws_region}.amazonaws.com"
}

output "cloudfront_origin_path" {
  description = "Origin path prefix for the API Gateway stage"
  value       = "/${aws_apigatewayv2_stage.prod.name}"
}

output "cloudfront_path_pattern" {
  description = "CloudFront path pattern for passthrough routes"
  value       = "/${var.api_route_prefix}/*"
}

output "passthrough_hub-central_url" {
  description = "Direct API Gateway passthrough health endpoint"
  value       = "${aws_apigatewayv2_stage.prod.invoke_url}/${var.api_route_prefix}/health"
}

output "alb_dns_name" {
  description = "Internal ALB DNS name when created by this module"
  value       = local.create_network ? aws_lb.app[0].dns_name : null
}

output "alb_listener_arn" {
  description = "ALB listener ARN used by the passthrough integration"
  value       = local.alb_listener_arn
}

output "ec2_private_ip" {
  description = "Private IP of the sample application EC2 instance when created by this module"
  value       = local.create_network ? aws_instance.app[0].private_ip : null
}

output "vpc_id" {
  description = "VPC ID used by the passthrough stack"
  value       = local.vpc_id
}

output "network_mode" {
  description = "Network provisioning mode in use"
  value       = var.network_mode
}
