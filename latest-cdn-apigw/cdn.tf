provider "aws" {
  region = var.aws_region
}

locals {
  private_content_bucket_name = format(var.bucket_prefix_pvt, var.env, var.cdn_name)
  rest_api_origin_host        = "${aws_api_gateway_rest_api.hub_central.id}.execute-api.${var.aws_region}.amazonaws.com"
}

resource "aws_s3_bucket" "documents" {
  bucket = local.private_content_bucket_name
  acl    = var.access_control
}

resource "aws_s3_bucket_public_access_block" "documents" {
  bucket = aws_s3_bucket.documents.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create the CloudFront OAI
resource "aws_cloudfront_origin_access_identity" "documents-identity" {
  comment = "Cloudfront identity for access to S3 Bucket"
}

# Set up the CDN
resource "aws_cloudfront_distribution" "documents" {
  origin {
    domain_name = aws_s3_bucket.documents.bucket_regional_domain_name
    origin_id   = "s3"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.documents-identity.cloudfront_access_identity_path
    }
  }

  origin {
    domain_name = local.rest_api_origin_host
    origin_id   = "api-gateway"
    origin_path = "/${aws_api_gateway_stage.prod.stage_name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  dynamic "origin" {
    for_each = var.enable_apigw_passthrough ? [module.apigw_passthrough[0]] : []
    content {
      domain_name = origin.value.cloudfront_origin_domain
      origin_id   = "apigw-passthrough"
      origin_path = origin.value.cloudfront_origin_path

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Distribution of signed S3 objects"
  default_root_object = "index.html"

  ordered_cache_behavior {
    path_pattern     = "/status*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "api-gateway"
    compress         = false

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.enable_apigw_passthrough ? [module.apigw_passthrough[0]] : []
    content {
      path_pattern     = ordered_cache_behavior.value.cloudfront_path_pattern
      allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods   = ["GET", "HEAD"]
      target_origin_id = "apigw-passthrough"
      compress         = false

      forwarded_values {
        query_string = true

        cookies {
          forward = "none"
        }
      }

      viewer_protocol_policy = "redirect-to-https"
      min_ttl                = 0
      default_ttl            = 0
      max_ttl                = 0
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"] # reads only
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3"
    compress         = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA"]
    }
  }

  tags = {
    Name = "${var.env}-${var.cdn_name}-hub-central-ui"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  depends_on = [
    aws_api_gateway_stage.prod,
    module.apigw_passthrough,
  ]
}

resource "aws_s3_bucket_object" "index" {
  bucket       = aws_s3_bucket.documents.id
  key          = "index.html"
  source       = "${path.module}/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/index.html")
}


resource "aws_s3_bucket_policy" "documents" {
  bucket = aws_s3_bucket.documents.id
  policy = data.aws_iam_policy_document.documents-cloudfront-policy.json
}


data "aws_iam_policy_document" "documents-cloudfront-policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.documents-identity.iam_arn]
    }
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${aws_s3_bucket.documents.arn}/*",
    ]
  }
}

