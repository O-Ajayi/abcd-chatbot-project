resource "aws_apigatewayv2_api" "passthrough" {
  name          = "${local.name_prefix}-http-api"
  protocol_type = "HTTP"
  description   = "HTTP API passthrough to private ALB"

  cors_configuration {
    allow_credentials = false
    allow_headers     = ["*"]
    allow_methods     = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "PATCH", "DELETE"]
    allow_origins     = ["*"]
    max_age           = 300
  }

  tags = {
    Name = "${local.name_prefix}-http-api"
  }
}

resource "aws_apigatewayv2_authorizer" "passthrough" {
  api_id                            = aws_apigatewayv2_api.passthrough.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.passthrough_authorizer.invoke_arn
  identity_sources                  = ["$context.routeKey"]
  name                              = "${local.name_prefix}-lambda-authorizer"
  authorizer_payload_format_version = "2.0"
  enable_simple_responses           = true
  authorizer_result_ttl_in_seconds  = 0
}

resource "aws_apigatewayv2_vpc_link" "passthrough" {
  name               = "${local.name_prefix}-vpc-link"
  subnet_ids         = local.private_subnet_ids
  security_group_ids = [local.vpc_link_security_group_id]

  tags = {
    Name = "${local.name_prefix}-vpc-link"
  }
}

resource "aws_apigatewayv2_integration" "alb" {
  api_id                 = aws_apigatewayv2_api.passthrough.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.passthrough.id
  integration_uri        = local.alb_listener_arn
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "proxy" {
  api_id             = aws_apigatewayv2_api.passthrough.id
  route_key          = "ANY /{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.alb.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.passthrough.id
}

resource "aws_apigatewayv2_route" "root" {
  api_id             = aws_apigatewayv2_api.passthrough.id
  route_key          = "ANY /"
  target             = "integrations/${aws_apigatewayv2_integration.alb.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.passthrough.id
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.passthrough.id
  name        = "prod"
  auto_deploy = true

  tags = {
    Name = "${local.name_prefix}-prod"
  }
}
