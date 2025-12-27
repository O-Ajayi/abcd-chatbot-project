# IAM Role for Lambda Functions
resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-${var.environment}-lambda-role"

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

  tags = var.tags
}

# IAM Policy for Lambda Functions
resource "aws_iam_role_policy" "lambda" {
  name = "${var.project_name}-${var.environment}-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
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
        Resource = values(var.dynamodb_tables)
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.sqs_queue_arn
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = var.sns_topic_arn
      },
      {
        Effect = "Allow"
        Action = [
          "lex:RecognizeText",
          "lex:RecognizeUtterance"
        ]
        Resource = "*"
      },
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
          "kendra:Query",
          "kendra:Retrieve"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${var.kendra_data_source_bucket != "" ? "arn:aws:s3:::${var.kendra_data_source_bucket}" : "*"}/*",
          "${var.kendra_data_source_bucket != "" ? "arn:aws:s3:::${var.kendra_data_source_bucket}" : "*"}",
          "${var.lex_bot_logs_bucket != "" ? "arn:aws:s3:::${var.lex_bot_logs_bucket}" : "*"}/*",
          "${var.lex_bot_logs_bucket != "" ? "arn:aws:s3:::${var.lex_bot_logs_bucket}" : "*"}"
        ]
      }
    ]
  })
}

# VPC Configuration for Lambda (if VPC is provided)
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  count = var.vpc_id != null ? 1 : 0

  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Lambda Functions
resource "aws_lambda_function" "functions" {
  for_each = {
    for idx, func in var.lambda_functions : func.name => func
  }

  function_name = "${var.project_name}-${var.environment}-${each.value.name}"
  role          = aws_iam_role.lambda.arn
  handler       = each.value.handler
  runtime       = each.value.runtime
  timeout       = each.value.timeout
  memory_size   = each.value.memory_size

  # Use built package if available, otherwise placeholder from packages directory
  filename         = var.lambda_package_paths != null && contains(keys(var.lambda_package_paths), each.value.name) ? var.lambda_package_paths[each.value.name] : "${path.root}/../packages/placeholder.zip"
  source_code_hash = var.lambda_package_paths != null && contains(keys(var.lambda_package_paths), each.value.name) ? filebase64sha256(var.lambda_package_paths[each.value.name]) : filebase64sha256("${path.root}/../packages/placeholder.zip")

  dynamic "environment" {
    for_each = [1]
    content {
      variables = merge(
        each.value.environment_variables,
        {
          RDS_ENDPOINT          = var.rds_endpoint != "" ? var.rds_endpoint : ""
          RDS_USERNAME          = var.rds_username != "" ? var.rds_username : ""
          RDS_PASSWORD          = var.rds_password != "" ? var.rds_password : ""
          RDS_DATABASE_NAME     = var.rds_database_name != "" ? var.rds_database_name : ""
          SQS_QUEUE_URL         = var.sqs_queue_url != "" ? var.sqs_queue_url : ""
          SNS_TOPIC_ARN         = var.sns_topic_arn
          DYNAMODB_TABLES       = jsonencode(var.dynamodb_tables)
          DYNAMODB_HISTORY_TABLE = var.dynamodb_table_names != null && var.dynamodb_table_names["Chatbot-ConversationHistory"] != null ? var.dynamodb_table_names["Chatbot-ConversationHistory"] : ""
          DYNAMODB_REVIEWER_TABLE = var.dynamodb_table_names != null && var.dynamodb_table_names["Chatbot-Conversation-Reviewer"] != null ? var.dynamodb_table_names["Chatbot-Conversation-Reviewer"] : ""
          KENDRA_DATA_SOURCE_BUCKET = var.kendra_data_source_bucket != "" ? var.kendra_data_source_bucket : ""
          LEX_BOT_LOGS_BUCKET   = var.lex_bot_logs_bucket != "" ? var.lex_bot_logs_bucket : ""
        }
      )
    }
  }

  dynamic "vpc_config" {
    for_each = var.subnet_ids != null && length(var.subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids != null ? var.security_group_ids : []
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-${each.value.name}"
    }
  )

  depends_on = [aws_iam_role_policy_attachment.lambda_vpc]
}

# Placeholder zip file is created manually
# Users should replace this with their actual Lambda function code

# SQS Event Source Mapping (for chatbot-reviewer lambda)
resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.functions["chatbot-reviewer"].arn
  enabled          = true
  batch_size       = 10
}

