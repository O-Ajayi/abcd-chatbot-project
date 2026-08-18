output "buckname" {
  value = var.create_cdn ? aws_s3_bucket.documents[0].id : null
}

output "create_cdn" {
  description = "Whether a new CloudFront distribution was created"
  value       = var.create_cdn
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = var.create_cdn ? aws_cloudfront_distribution.documents[0].domain_name : var.existing_cloudfront_domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = var.create_cdn ? aws_cloudfront_distribution.documents[0].id : var.existing_cloudfront_distribution_id
}

output "hub_central_ui_url" {
  description = "CloudFront URL for the hub-central-ui"
  value = var.create_cdn ? "https://${aws_cloudfront_distribution.documents[0].domain_name}" : (
    var.existing_cloudfront_domain_name != "" ? "https://${var.existing_cloudfront_domain_name}" : null
  )
}

output "apigw_passthrough_enabled" {
  description = "Whether the passthrough stack is enabled"
  value       = var.enable_apigw_passthrough
}

output "apigw_passthrough_cdn_url" {
  description = "Passthrough endpoint via CloudFront (when CDN is enabled)"
  value = var.enable_apigw_passthrough && (var.create_cdn || var.existing_cloudfront_domain_name != "") ? (
    var.apigw_passthrough_route_prefix != "" ?
    "https://${var.create_cdn ? aws_cloudfront_distribution.documents[0].domain_name : var.existing_cloudfront_domain_name}/${var.apigw_passthrough_route_prefix}" :
    "https://${var.create_cdn ? aws_cloudfront_distribution.documents[0].domain_name : var.existing_cloudfront_domain_name}"
  ) : null
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

output "apigw_passthrough_using_existing_alb" {
  description = "Whether an existing ALB was wired instead of creating a new one"
  value       = length(module.apigw_passthrough) > 0 ? module.apigw_passthrough[0].using_existing_alb : false
}

output "apigw_passthrough_cloudfront_origin_config" {
  description = "CloudFront origin settings to add manually when create_cdn is false"
  value = var.enable_apigw_passthrough && !var.create_cdn ? {
    origin_domain = module.apigw_passthrough[0].cloudfront_origin_domain
    origin_path   = module.apigw_passthrough[0].cloudfront_origin_path
    path_pattern  = module.apigw_passthrough[0].cloudfront_path_pattern
  } : null
}
