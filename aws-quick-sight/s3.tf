resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "quicksight_data" {
  bucket = local.bucket_name
}

resource "aws_s3_bucket_public_access_block" "quicksight_data" {
  bucket = aws_s3_bucket.quicksight_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "quicksight_data" {
  bucket = aws_s3_bucket.quicksight_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "sales_csv" {
  bucket       = aws_s3_bucket.quicksight_data.id
  key          = "data/sales.csv"
  source       = "${path.module}/sample-data/sales.csv"
  content_type = "text/csv"
  etag         = filemd5("${path.module}/sample-data/sales.csv")
}

resource "aws_s3_object" "manifest" {
  bucket       = aws_s3_bucket.quicksight_data.id
  key          = "manifests/sales-manifest.json"
  content_type = "application/json"
  content = jsonencode({
    fileLocations = [
      {
        URIPrefixes = [
          "s3://${aws_s3_bucket.quicksight_data.bucket}/data/"
        ]
      }
    ]
    globalUploadSettings = {
      format         = "CSV"
      delimiter      = ","
      textqualifier  = "\""
      containsHeader = true
    }
  })
}
