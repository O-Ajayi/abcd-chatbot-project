output "buckname" {
  value = aws_s3_bucket.documents.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.documents.domain_name
}

output "hub_central_ui_url" {
  description = "CloudFront URL for the hub-central-ui"
  value       = "https://${aws_cloudfront_distribution.documents.domain_name}"
}

output "hub_central_status_endpoint" {
  description = "Status endpoint via CloudFront (same origin as the UI)"
  value       = "https://${aws_cloudfront_distribution.documents.domain_name}/status"
}

output "api_gateway_invoke_url" {
  description = "Direct API Gateway invoke URL for the status route"
  value       = "${aws_api_gateway_stage.prod.invoke_url}/status"
}

output "lambda_function_name" {
  description = "Lambda function backing the status API"
  value       = aws_lambda_function.hub_central_status.function_name
}

output "apigw_passthrough_enabled" {
  description = "Whether the passthrough stack is enabled"
  value       = var.enable_apigw_passthrough
}

output "apigw_passthrough_cdn_url" {
  description = "Passthrough hub-central endpoint via CloudFront"
  value       = var.enable_apigw_passthrough ? "https://${aws_cloudfront_distribution.documents.domain_name}/${var.apigw_passthrough_route_prefix}/health" : null
}

output "apigw_passthrough_api_url" {
  description = "Direct API Gateway passthrough endpoint"
  value       = var.enable_apigw_passthrough ? module.apigw_passthrough[0].passthrough_hub-central_url : null
}

output "apigw_passthrough_alb_dns_name" {
  description = "Internal ALB DNS name for the sample application"
  value       = var.enable_apigw_passthrough ? module.apigw_passthrough[0].alb_dns_name : null
}

# output "hosted_zone_name" {
#   value = aws_route53_zone.documents.id
# }
