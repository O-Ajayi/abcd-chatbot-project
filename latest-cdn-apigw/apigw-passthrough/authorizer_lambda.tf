data "archive_file" "passthrough_authorizer_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/authorizer.py"
  output_path = "${path.module}/lambda/authorizer.zip"
}

resource "aws_iam_role" "passthrough_authorizer_lambda" {
  name = "${local.name_prefix}-authorizer-lambda"

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

  tags = {
    Name = "${local.name_prefix}-authorizer-lambda"
  }
}

resource "aws_iam_role_policy_attachment" "passthrough_authorizer_lambda_logs" {
  role       = aws_iam_role.passthrough_authorizer_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "passthrough_authorizer" {
  filename         = data.archive_file.passthrough_authorizer_lambda.output_path
  source_code_hash = data.archive_file.passthrough_authorizer_lambda.output_base64sha256
  function_name    = "${local.name_prefix}-authorizer"
  role             = aws_iam_role.passthrough_authorizer_lambda.arn
  handler          = "authorizer.handler"
  runtime          = "python3.12"
  timeout          = 10

  tags = {
    Name = "${local.name_prefix}-authorizer"
  }
}

resource "aws_lambda_permission" "passthrough_authorizer_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGatewayAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.passthrough_authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.passthrough.execution_arn}/authorizers/*"
}
