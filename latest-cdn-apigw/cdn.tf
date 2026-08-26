provider "aws" {
  region = var.aws_region
}

locals {
  private_content_bucket_name = format(var.bucket_prefix_pvt, var.env, var.cdn_name)
}

resource "aws_s3_bucket" "documents" {
  count  = var.create_cdn ? 1 : 0
  bucket = local.private_content_bucket_name
}

resource "aws_s3_bucket_ownership_controls" "documents" {
  count  = var.create_cdn ? 1 : 0
  bucket = aws_s3_bucket.documents[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "documents" {
  count      = var.create_cdn ? 1 : 0
  depends_on = [aws_s3_bucket_ownership_controls.documents]

  bucket = aws_s3_bucket.documents[0].id
  acl    = var.access_control
}

resource "aws_s3_bucket_public_access_block" "documents" {
  count  = var.create_cdn ? 1 : 0
  bucket = aws_s3_bucket.documents[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_identity" "documents-identity" {
  count   = var.create_cdn ? 1 : 0
  comment = "Cloudfront identity for access to S3 Bucket"
}

resource "aws_cloudfront_distribution" "documents" {
  count = var.create_cdn ? 1 : 0

  origin {
    domain_name = aws_s3_bucket.documents[0].bucket_regional_domain_name
    origin_id   = "s3"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.documents-identity[0].cloudfront_access_identity_path
    }
  }

  dynamic "origin" {
    for_each = var.enable_apigw_passthrough && var.apigw_passthrough_route_prefix != "" ? [module.apigw_passthrough[0]] : []
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

  dynamic "ordered_cache_behavior" {
    for_each = var.enable_apigw_passthrough && var.apigw_passthrough_route_prefix != "" ? [module.apigw_passthrough[0]] : []
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
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
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
    module.apigw_passthrough,
  ]
}

resource "aws_s3_object" "index" {
  count        = var.create_cdn ? 1 : 0
  bucket       = aws_s3_bucket.documents[0].id
  key          = "index.html"
  source       = "${path.module}/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/index.html")
}

resource "aws_s3_bucket_policy" "documents" {
  count  = var.create_cdn ? 1 : 0
  bucket = aws_s3_bucket.documents[0].id
  policy = data.aws_iam_policy_document.documents-cloudfront-policy[0].json
}

data "aws_iam_policy_document" "documents-cloudfront-policy" {
  count = var.create_cdn ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.documents-identity[0].iam_arn]
    }
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${aws_s3_bucket.documents[0].arn}/*",
    ]
  }
}