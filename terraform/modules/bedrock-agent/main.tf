# IAM Role for Bedrock Agent
resource "aws_iam_role" "bedrock_agent" {
  name = "${var.project_name}-${var.environment}-bedrock-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for Bedrock Agent
resource "aws_iam_role_policy" "bedrock_agent" {
  name = "${var.project_name}-${var.environment}-bedrock-agent-policy"
  role = aws_iam_role.bedrock_agent.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = values(var.lambda_function_arns)
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = values(var.dynamodb_table_arns)
      },
      {
        Effect = "Allow"
        Action = [
          "kendra:Query",
          "kendra:Retrieve"
        ]
        Resource = var.create_kendra_index ? aws_kendra_index.main[0].arn : "*"
      }
    ]
  })
}

# Kendra Index (if enabled)
resource "aws_kendra_index" "main" {
  count = var.create_kendra_index ? 1 : 0

  name     = "${var.project_name}-${var.environment}-${var.kendra_index_name}"
  role_arn = aws_iam_role.kendra[0].arn
  edition  = var.kendra_edition

  tags = var.tags
}

# IAM Role for Kendra
resource "aws_iam_role" "kendra" {
  count = var.create_kendra_index ? 1 : 0

  name = "${var.project_name}-${var.environment}-kendra-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "kendra.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for Kendra
resource "aws_iam_role_policy" "kendra" {
  count = var.create_kendra_index ? 1 : 0

  name = "${var.project_name}-${var.environment}-kendra-policy"
  role = aws_iam_role.kendra[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "Kendra"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/aws/kendra/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogStreams",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/aws/kendra/*:log-stream:*"
      }
    ]
  })
}

# Bedrock Agent
# Note: AWS Bedrock agents are created via the Bedrock API
# For full implementation, consider using the terraform-aws-bedrock module from:
# https://github.com/aws-ia/terraform-aws-bedrock
# 
# This is a placeholder that sets up the necessary IAM roles and Kendra index.
# The actual Bedrock agent should be created using the AWS Console or via the module.
#
# To use the terraform-aws-bedrock module, uncomment and configure:
#
# module "bedrock" {
#   source = "aws-ia/bedrock/aws"
#   
#   # Configure according to module documentation
# }

# Output the role ARN for manual Bedrock agent creation
# Users can create the agent via AWS Console or CLI using this role

