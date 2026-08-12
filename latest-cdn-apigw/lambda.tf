data "archive_file" "hub_central_status_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/handler.py"
  output_path = "${path.module}/lambda/handler.zip"
}

resource "aws_iam_role" "hub_central_status_lambda" {
  name = "${var.env}-${var.cdn_name}-hub-central-status-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "hub_central_status_lambda_logs" {
  role       = aws_iam_role.hub_central_status_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "hub_central_status" {
  filename         = data.archive_file.hub_central_status_lambda.output_path
  source_code_hash = data.archive_file.hub_central_status_lambda.output_base64sha256
  function_name    = "${var.env}-${var.cdn_name}-hub-central-status"
  role             = aws_iam_role.hub_central_status_lambda.arn
  handler          = "handler.handler"
  runtime          = "python3.9"
  timeout          = 10

  tags = {
    Name = "${var.env}-${var.cdn_name}-hub-central-status"
  }
}
