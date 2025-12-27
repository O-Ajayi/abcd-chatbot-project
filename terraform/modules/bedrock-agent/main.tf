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
# Reference: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrock_agent
resource "aws_bedrock_agent" "main" {
  agent_name                 = "${var.project_name}-${var.environment}-${var.agent_name}"
  agent_resource_role_arn    = aws_iam_role.bedrock_agent.arn
  foundation_model           = var.foundation_model
  instruction                = var.instruction != null ? var.instruction : "You are a helpful chatbot assistant. Use the provided knowledge base and tools to answer questions accurately. Provide clear and concise responses to user queries."
  description                = var.agent_description != null ? var.agent_description : "Chatbot agent for ${var.project_name}"
  idle_session_ttl_in_seconds = var.idle_session_ttl != null ? var.idle_session_ttl : 1800

  dynamic "prompt_override_configuration" {
    for_each = var.prompt_override_configuration != null ? [var.prompt_override_configuration] : []
    content {
      prompt_configs {
        base_prompt_template = prompt_override_configuration.value.base_prompt_template
        inference_configuration {
          max_tokens                 = try(prompt_override_configuration.value.inference_configuration.max_tokens, null)
          temperature                = try(prompt_override_configuration.value.inference_configuration.temperature, null)
          top_p                      = try(prompt_override_configuration.value.inference_configuration.top_p, null)
          top_k                      = try(prompt_override_configuration.value.inference_configuration.top_k, null)
        }
      }
    }
  }

  tags = var.tags
}

# Bedrock Agent Alias
# Reference: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrock_agent_alias
resource "aws_bedrock_agent_alias" "main" {
  agent_id     = aws_bedrock_agent.main.agent_id
  agent_alias_name = "${var.project_name}-${var.environment}-${var.agent_name}-alias"
  description  = "Alias for ${var.agent_name} agent"

  tags = var.tags
}

# Bedrock Knowledge Base (if Kendra is enabled)
# Note: Bedrock Knowledge Bases can use Kendra as a data source
# Reference: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrock_knowledge_base
resource "aws_bedrock_knowledge_base" "main" {
  count = var.create_kendra_index && var.create_knowledge_base ? 1 : 0

  name     = "${var.project_name}-${var.environment}-${var.kendra_index_name}"
  role_arn = aws_iam_role.kendra[0].arn
  type     = "VECTOR"

  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_configuration {
        embedding_model_arn = var.embedding_model_arn != null ? var.embedding_model_arn : "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v1"
      }
    }
  }

  storage_configuration {
    type = "VECTOR"
    vector_configuration {
      embedding_model_configuration {
        embedding_model_arn = var.embedding_model_arn != null ? var.embedding_model_arn : "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v1"
      }
    }
  }

  tags = var.tags
}

# Bedrock Data Source for Knowledge Base (S3)
resource "aws_bedrock_data_source" "s3" {
  count = var.create_kendra_index && var.create_knowledge_base && var.kb_s3_data_source != null ? 1 : 0

  knowledge_base_id = aws_bedrock_knowledge_base.main[0].knowledge_base_id
  name              = "${var.project_name}-${var.environment}-s3-data-source"
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = var.kb_s3_data_source
    }
  }
}

