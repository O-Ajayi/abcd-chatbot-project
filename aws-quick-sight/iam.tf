resource "aws_iam_role" "quicksight_s3" {
  name = "${local.name_prefix}-s3-access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "quicksight.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}
resource "aws_iam_role_policy" "quicksight_s3" {
  name = "${local.name_prefix}-s3-read"
  role = aws_iam_role.quicksight_s3.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.quicksight_data.arn
      },
      {
        Sid    = "ReadObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${aws_s3_bucket.quicksight_data.arn}/*"
      }
    ]
  })
}
resource "aws_s3_bucket_policy" "quicksight_data" {
  bucket = aws_s3_bucket.quicksight_data.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowQuickSightRoleRead"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.quicksight_s3.arn
        }
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.quicksight_data.arn
      },
      {
        Sid    = "AllowQuickSightRoleObjectRead"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.quicksight_s3.arn
        }
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${aws_s3_bucket.quicksight_data.arn}/*"
      }
    ]
  })
}