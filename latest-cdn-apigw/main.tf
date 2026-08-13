terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
  required_version = ">= 0.12"
}

# locals {
#   private_content_bucket_name = format(var.bucket_prefix_pvt, var.env, var.cdn_name)
# }

# resource "aws_s3_bucket" "documents" {
#   bucket = local.private_content_bucket_name
#   acl    = var.access_control
# }

# resource "aws_s3_bucket_public_access_block" "documents" {
#   bucket = aws_s3_bucket.documents.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }
