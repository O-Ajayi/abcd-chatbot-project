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

output "passthrough_demo_url" {
  description = "Direct API Gateway passthrough health endpoint"
  value       = "${aws_apigatewayv2_stage.prod.invoke_url}/${var.api_route_prefix}/health"
}

output "authorizer_lambda_name" {
  description = "Lambda authorizer function name for passthrough routes"
  value       = aws_lambda_function.passthrough_authorizer.function_name
}

output "authorizer_lambda_arn" {
  description = "Lambda authorizer function ARN"
  value       = aws_lambda_function.passthrough_authorizer.arn
}

output "alb_dns_name" {
  description = "Internal ALB DNS name"
  value       = aws_lb.app.dns_name
}

output "alb_listener_arn" {
  description = "ALB listener ARN used by the passthrough integration"
  value       = aws_lb_listener.http.arn
}

output "ec2_private_ip" {
  description = "Private IP of the sample application EC2 instance"
  value       = aws_instance.app.private_ip
}

output "vpc_id" {
  description = "VPC ID used by the passthrough stack"
  value       = local.vpc_id
}

output "network_mode" {
  description = "Network provisioning mode in use"
  value       = var.network_mode
}
