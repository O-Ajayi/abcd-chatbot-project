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

  sample_utterances {
    utterance = each.value.utterances
  }

  fulfillment_code_hook {
    enabled = true
  }
}

# Lex V2 Bot Version
resource "aws_lexv2models_bot_version" "main" {
  bot_id = aws_lexv2models_bot.main.id

  description = "Production version of ${var.bot_name}"

  depends_on = [
    aws_lexv2models_bot_locale.main,
    aws_lexv2models_intent.intents
  ]
}

# Lex V2 Bot Alias
resource "aws_lexv2models_bot_alias" "main" {
  bot_alias_name = "${var.project_name}-${var.environment}-alias"
  bot_id         = aws_lexv2models_bot.main.id
  bot_version    = aws_lexv2models_bot_version.main.bot_version

  description = "Alias for ${var.bot_name}"

  bot_alias_locale_settings {
    bot_alias_locale_setting {
      locale_id = var.locale_id
      enabled   = true

      code_hook_specification {
        lambda_code_hook {
          code_hook_interface_version = "1.0"
          lambda_arn                  = var.lambda_function_arn
        }
      }
    }
  }

  tags = var.tags
}

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

# Lambda Permission for Lex
resource "aws_lambda_permission" "lex" {
  statement_id  = "AllowExecutionFromLex"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_arn
  principal     = "lexv2.amazonaws.com"
  source_arn    = "${aws_lexv2models_bot.main.arn}/*"
}

