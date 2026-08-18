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
  value       = var.api_route_prefix != "" ? "/${var.api_route_prefix}/*" : "/*"
}

output "passthrough_demo_url" {
  description = "Direct API Gateway passthrough endpoint (forwards to ALB root path)"
  value       = aws_apigatewayv2_stage.prod.invoke_url
}

output "authorizer_lambda_name" {
  description = "Lambda authorizer function name for passthrough routes"
  value       = aws_lambda_function.passthrough_authorizer.function_name
}

output "authorizer_lambda_arn" {
  description = "Lambda authorizer function ARN"
  value       = aws_lambda_function.passthrough_authorizer.arn
}

output "using_existing_alb" {
  description = "Whether an existing ALB was wired instead of creating a new one"
  value       = local.use_existing_alb
}

output "alb_dns_name" {
  description = "Internal ALB DNS name"
  value       = local.alb_dns_name
}

output "alb_listener_arn" {
  description = "ALB listener ARN used by the passthrough integration"
  value       = local.alb_listener_arn
}

output "alb_arn" {
  description = "ALB ARN used by the passthrough integration"
  value       = local.use_existing_alb ? data.aws_lb.existing[0].arn : aws_lb.app[0].arn
}

output "ec2_private_ip" {
  description = "Private IP of the sample application EC2 instance"
  value       = local.create_alb ? aws_instance.app[0].private_ip : null
}

output "vpc_id" {
  description = "VPC ID used by the passthrough stack"
  value       = local.vpc_id
}

output "network_mode" {
  description = "Network provisioning mode in use"
  value       = var.network_mode
}

output "vpc_link_security_group_id" {
  description = "Security group ID attached to the API Gateway VPC link"
  value       = local.vpc_link_security_group_id
}
