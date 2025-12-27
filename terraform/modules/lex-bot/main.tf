# Lex V2 Bot
resource "aws_lexv2models_bot" "main" {
  name     = "${var.project_name}-${var.environment}-${var.bot_name}"
  role_arn = aws_iam_role.lex.arn

  data_privacy {
    child_directed = false
  }

  idle_session_ttl_in_seconds = 300

  tags = var.tags
}

# Lex V2 Bot Locale
resource "aws_lexv2models_bot_locale" "main" {
  bot_id      = aws_lexv2models_bot.main.id
  bot_version = "DRAFT"
  locale_id   = var.locale_id

  n_lu_intent_confidence_threshold = 0.4
}

# Lex V2 Intents
resource "aws_lexv2models_intent" "intents" {
  for_each = {
    for idx, intent in var.sample_intents : intent.name => intent
  }

  bot_id      = aws_lexv2models_bot.main.id
  bot_version = "DRAFT"
  locale_id   = var.locale_id
  name        = each.value.name

  description = each.value.description

  # Sample utterances - use dynamic block for multiple utterances
  dynamic "sample_utterance" {
    for_each = each.value.utterances
    content {
      utterance = sample_utterance.value
    }
  }

  fulfillment_code_hook {
    enabled = true
  }
}

# Lex V2 Bot Version
# Reference: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lexv2models_bot_version
resource "aws_lexv2models_bot_version" "main" {
  bot_id = aws_lexv2models_bot.main.id

  description = "Production version of ${var.bot_name}"

  locale_specification = {
    (var.locale_id) = {
      source_bot_version = "DRAFT"
    }
  }

  depends_on = [
    aws_lexv2models_bot_locale.main,
    aws_lexv2models_intent.intents
  ]
}

# Lex V2 Bot Alias
# Note: The aws_lexv2models_bot_alias resource type is not available in the current AWS provider
# Bot aliases should be created via AWS Console, CLI, or using the AWS Cloud Control API provider
# For now, we'll comment this out and users can create aliases manually or via CLI
# Example CLI command:
# aws lexv2-models create-bot-alias --bot-id <bot-id> --bot-alias-name <alias-name> --bot-version <version>
#
# resource "aws_lexv2models_bot_alias" "main" {
#   bot_alias_name = "${var.project_name}-${var.environment}-alias"
#   bot_id         = aws_lexv2models_bot.main.id
#   bot_version    = aws_lexv2models_bot_version.main.bot_version
#   description    = "Alias for ${var.bot_name}"
#   tags           = var.tags
# }

# IAM Role for Lex
resource "aws_iam_role" "lex" {
  name = "${var.project_name}-${var.environment}-lex-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lexv2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for Lex to invoke Lambda
resource "aws_iam_role_policy" "lex_lambda" {
  name = "${var.project_name}-${var.environment}-lex-lambda-policy"
  role = aws_iam_role.lex.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = var.lambda_function_arn
      }
    ]
  })
}

# Lambda Permission for Lex (only if Lambda function ARN is provided)
resource "aws_lambda_permission" "lex" {
  count = var.lambda_function_arn != null ? 1 : 0

  statement_id  = "AllowExecutionFromLex"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_arn
  principal     = "lexv2.amazonaws.com"
  source_arn    = "${aws_lexv2models_bot.main.arn}/*"
}

