# Lex V2 Bot
resource "aws_lexv2models_bot" "main" {
  name     = "${var.project_name}-${var.environment}-${var.bot_name}"
  role_arn = aws_iam_role.lex.arn
  type = "Bot"

  data_privacy {
    child_directed = false
  }

  idle_session_ttl_in_seconds = 600

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

# Flatten intents + slots for slot resources
locals {
  intent_slot_entries = flatten([
    for intent in var.sample_intents : [
      for slot in intent.slots : {
        intent_name              = intent.name
        slot_name                = slot.name
        slot_type                = slot.slot_type
        value_elicitation_prompt = slot.value_elicitation_prompt
      }
    ]
  ])
  intent_slots_map = {
    for entry in local.intent_slot_entries : "${entry.intent_name}_${entry.slot_name}" => entry
  }
  lex_region_flag = var.aws_region != null ? format(" --region %s", var.aws_region) : ""
}

# Lex V2 Slots (per-intent slots used in fulfillment)
resource "aws_lexv2models_slot" "slots" {
  for_each = local.intent_slots_map

  bot_id      = aws_lexv2models_bot.main.id
  bot_version = "DRAFT"
  intent_id   = aws_lexv2models_intent.intents[each.value.intent_name].intent_id
  locale_id   = var.locale_id
  name        = each.value.slot_name
  slot_type_id = each.value.slot_type

  value_elicitation_setting {
    slot_constraint = "Required"

    prompt_specification {
      allow_interrupt = true
      max_retries     = 2
      message_selection_strategy = "Random"
      message_group {
        message {
          plain_text_message {
            value = each.value.value_elicitation_prompt
          }
        }
      }

      prompt_attempts_specification {
        allow_interrupt = true
        map_block_key   = "Initial"
        allowed_input_types {
          allow_audio_input = true
          allow_dtmf_input  = false
        }
        audio_and_dtmf_input_specification {
          start_timeout_ms = 4000
          audio_specification {
            end_timeout_ms   = 640
            max_length_ms    = 15000
          }
          dtmf_specification {
            deletion_character = "*"
            end_character     = "#"
            end_timeout_ms     = 5000
            max_length         = 5
          }
        }
        text_input_specification {
          start_timeout_ms = 30000
        }
      }
      prompt_attempts_specification {
        allow_interrupt = true
        map_block_key   = "Retry1"
        allowed_input_types {
          allow_audio_input = true
          allow_dtmf_input  = false
        }
        audio_and_dtmf_input_specification {
          start_timeout_ms = 4000
          audio_specification {
            end_timeout_ms   = 640
            max_length_ms    = 15000
          }
          dtmf_specification {
            deletion_character = "*"
            end_character     = "#"
            end_timeout_ms     = 5000
            max_length         = 5
          }
        }
        text_input_specification {
          start_timeout_ms = 30000
        }
      }
    }
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
    aws_lexv2models_intent.intents,
    aws_lexv2models_slot.slots,
    null_resource.lex_build_locale,
  ]
}

# Build bot locale (DRAFT) so NLU is ready before creating bot version. When lex_skip_build_locale is true, this no-ops.
resource "null_resource" "lex_build_locale" {
  triggers = {
    bot_id     = aws_lexv2models_bot.main.id
    locale_id  = var.locale_id
    intents    = jsonencode([for i in var.sample_intents : { name = i.name, slots = i.slots }])
    skip_build = var.lex_skip_build_locale
  }

  depends_on = [
    aws_lexv2models_bot_locale.main,
    aws_lexv2models_intent.intents,
    aws_lexv2models_slot.slots,
  ]

  provisioner "local-exec" {
    # When LEX_SKIP_BUILD=true, skip build. Otherwise wait for "Built" so the locale is ready for CreateBotVersion.
    command = <<-EOT
      if [ "$${LEX_SKIP_BUILD}" = "true" ]; then echo "Skipping Lex build (lex_skip_build_locale=true)"; exit 0; fi
      aws lexv2-models build-bot-locale --bot-id ${aws_lexv2models_bot.main.id} --bot-version DRAFT --locale-id ${var.locale_id}${local.lex_region_flag} && aws lexv2-models wait bot-locale-built --bot-id ${aws_lexv2models_bot.main.id} --bot-version DRAFT --locale-id ${var.locale_id}${local.lex_region_flag}
    EOT
    environment = merge(
      var.aws_region != null ? { AWS_REGION = var.aws_region } : {},
      { LEX_SKIP_BUILD = var.lex_skip_build_locale ? "true" : "false" }
    )
  }
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

# OR Preferrably

# resource "null_resource" "main_alias" {
#   depends_on = [aws_lexv2models_bot_version.main]

#   triggers = {
#     bot_id         = aws_lexv2models_bot.main.id
#     locale_id      = aws_lexv2models_bot_locale.main.locale_id
#     latest_version = aws_lexv2models_bot_version.main.bot_version
#     lambda_arn     = "module.lambda_supportBot_app.lambda_arn"
#     logs_arn       = aws_cloudwatch_log_group.main.arn
#   }

#   provisioner "local-exec" {
#     command = "./upsert_bot_alias.sh ${aws_lexv2models_bot.main.id} ${aws_lexv2models_bot_locale.main.locale_id} ${aws_lexv2models_bot_version.main.bot_version} '${module.lambda_supportBot_app.lambda_arn}' '${aws_cloudwatch_log_group.main.arn}' 'us-east-1'"
#   }
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

# S3 Bucket for Lex Bot Logs
resource "aws_s3_bucket" "lex_bot_logs" {
  bucket = "${var.project_name}-${var.environment}-lex-bot-logs"

  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-lex-bot-logs"
      Purpose = "LexBotLogs"
    }
  )
}

resource "aws_s3_bucket_versioning" "lex_bot_logs" {
  bucket = aws_s3_bucket.lex_bot_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lex_bot_logs" {
  bucket = aws_s3_bucket.lex_bot_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "lex_bot_logs" {
  bucket = aws_s3_bucket.lex_bot_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "lex_bot_logs" {
  bucket = aws_s3_bucket.lex_bot_logs.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = var.lex_logs_retention_days
    }
  }
}