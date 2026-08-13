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

resource "aws_apigatewayv2_vpc_link" "passthrough" {
  name               = "${local.name_prefix}-vpc-link"
  subnet_ids         = local.private_subnet_ids
  security_group_ids = [aws_security_group.vpc_link.id]

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
  integration_uri        = aws_lb_listener.http.arn
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "app_health" {
  api_id    = aws_apigatewayv2_api.passthrough.id
  route_key = "GET /${var.api_route_prefix}/health"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}

resource "aws_apigatewayv2_route" "app_proxy" {
  api_id    = aws_apigatewayv2_api.passthrough.id
  route_key = "ANY /${var.api_route_prefix}/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}

resource "aws_apigatewayv2_route" "app_root" {
  api_id    = aws_apigatewayv2_api.passthrough.id
  route_key = "GET /${var.api_route_prefix}"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.passthrough.id
  name        = "prod"
  auto_deploy = true

  tags = {
    Name = "${local.name_prefix}-prod"
  }
}
