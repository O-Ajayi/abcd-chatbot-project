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

output "apigw_passthrough_enabled" {
  description = "Whether the passthrough stack is enabled"
  value       = var.enable_apigw_passthrough
}

output "apigw_passthrough_cdn_url" {
  description = "Passthrough demo endpoint via CloudFront"
  value = length(module.apigw_passthrough) > 0 ? "https://${aws_cloudfront_distribution.documents.domain_name}/${var.apigw_passthrough_route_prefix}/health" : null
}

output "apigw_passthrough_api_url" {
  description = "Direct API Gateway passthrough endpoint"
  value       = length(module.apigw_passthrough) > 0 ? module.apigw_passthrough[0].passthrough_demo_url : null
}

output "apigw_passthrough_authorizer_lambda" {
  description = "Lambda authorizer function for the passthrough HTTP API"
  value       = length(module.apigw_passthrough) > 0 ? module.apigw_passthrough[0].authorizer_lambda_name : null
}

output "apigw_passthrough_alb_dns_name" {
  description = "Internal ALB DNS name for the sample application"
  value       = length(module.apigw_passthrough) > 0 ? module.apigw_passthrough[0].alb_dns_name : null
}

# output "hosted_zone_name" {
#   value = aws_route53_zone.documents.id
# }
