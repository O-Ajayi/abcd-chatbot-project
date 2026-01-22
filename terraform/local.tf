# Local variables for Connect module configuration
locals {
  time_zone        = "EST"
  sales_weekdays   = ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY"]
  support_weekdays = ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY"]
  support_weekends = ["SUNDAY", "SATURDAY"]

  # Hours of Operations

  hours_of_operations = {
    sales = {
      description = "HOOP for Sales"
      time_zone   = local.time_zone
      config = [
        for w in local.sales_weekdays : {
          day = w
          start_time = {
            hours   = 8 # 8 AM
            minutes = 0
          }
          end_time = {
            hours   = 18 # 6 PM
            minutes = 0
          }
        }
      ]
    }
    support = {
      description = "HOOP for Support"
      time_zone   = local.time_zone
      config = flatten([
        [
          for w in local.support_weekdays : {
            day = w
            start_time = {
              hours   = 8 # 8 AM
              minutes = 0
            }
            end_time = {
              hours   = 18 # 6 PM
              minutes = 0
            }
          }
        ],
        flatten([
          for w in local.support_weekends : [
            # Second loop, need two start/end times per day, with break in between
            # 9 AM - 12PM, 1 PM - 5 PM
            for t in [{ start = 9, end = 12 }, { start = 13, end = 17 }] : {
              day = w
              start_time = {
                hours   = t.start
                minutes = 0
              }
              end_time = {
                hours   = t.end
                minutes = 0
              }
            }
          ]
        ])
      ])
    }
  }

  # Contact Flows - simplified to avoid circular dependencies
  contact_flows = {
    inbound = {
      content = templatefile(
        "${path.module}/contact-flows/inbound.json.tftpl",
        {
          sales_queue_arn   = try(module.connect[0].queues["sales"].arn, "")
          support_queue_arn = try(module.connect[0].queues["support"].arn, "")
          lambda_arn        = var.create_lambda_functions ? try(module.lambda_functions[0].lambda_arns["chatbot-processor"], "") : ""
          lex_bot_name      = var.create_lex_bot ? module.lex_bot[0].bot_id : ""
        }
      )
    }
    quick_connect = {
      type = "QUEUE_TRANSFER"
      content = templatefile(
        "${path.module}/contact-flows/quick_connect.json.tftpl",
        {
          support_queue_arn = try(module.connect[0].queues["support"].arn, "")
        }
      )
    }
  }

  queues = {
    sales = {
      hours_of_operation_id = try(module.connect[0].hours_of_operations["sales"].hours_of_operation_id, null)
      max_contacts          = 5
    }
    support = {
      hours_of_operation_id = try(module.connect[0].hours_of_operations["support"].hours_of_operation_id, null)
      max_contacts          = 9
    }
  }

  quick_connects = {
    phone_number = {
      quick_connect_config = {
        quick_connect_type = "PHONE_NUMBER"

        phone_config = {
          phone_number = "+18885551212"
        }
      }
    }
    queue = {
      quick_connect_config = {
        quick_connect_type = "QUEUE"

        queue_config = {
          contact_flow_id = try(module.connect[0].contact_flows["quick_connect"].contact_flow_id, null)
          queue_id        = try(module.connect[0].queues["sales"].queue_id, null)
        }
      }
    }
  }

  routing_profiles = {
    sales = {
      description               = "Routing profile for Sales"
      default_outbound_queue_id = try(module.connect[0].queues["sales"].queue_id, null)

      media_concurrencies = [
        {
          channel     = "VOICE"
          concurrency = 1 // Always 1 for Voice
        },
        {
          channel     = "CHAT"
          concurrency = 2 // between 1 and 5
        }
      ]

      queue_configs = [
        {
          channel  = "VOICE"
          delay    = 0
          priority = 1
          queue_id = try(module.connect[0].queues["sales"].queue_id, null)
        },
        {
          channel  = "CHAT"
          delay    = 0
          priority = 1
          queue_id = try(module.connect[0].queues["sales"].queue_id, null)
        }
      ]
    }
  }

  security_profiles = {
    example = {
      description = "Example security profile"

      permissions = [
        "BasicAgentAccess",
        "OutboundCallAccess",
      ]
    }
  }

  # Vocabularies
  vocabularies = {
    example_us = {
      content       = "Phrase\tIPA\tSoundsLike\tDisplayAs\nLos-Angeles\t\t\tLos Angeles\nF.B.I.\tɛ f b i aɪ\t\tFBI\nEtienne\t\teh-tee-en\t"
      language_code = "en-US"
    }
  }

  # Bot and Lambda Associations
  # Note: These are passed directly in module call to avoid circular dependencies
  # Empty by default - will be populated in module call if modules exist
  bot_associations = {}

  lambda_function_associations = {}

  users = {
    sales_agent = {
      password              = "SomeSecurePassword!1234" # Recommended to be passed in through variables if used
      hierarchy_group_key   = "child"
      routing_profile_key   = "sales"
      security_profile_keys = ["example"]

      identity_info = {
        email      = "sales@example.com"
        first_name = "Sales"
        last_name  = "Agent"
      }

      phone_config = {
        phone_type                    = "SOFT_PHONE"
        after_contact_work_time_limit = 5
        auto_accept                   = false
      }
    }
  }

  # User Hierarchy Groups
  user_hierarchy_groups = {
    parent = {}
    child = {
      parent_group_key = "parent"
    }
  }

  # User Hierarchy Structure
  user_hierarchy_structure = {
    level_one = "level-1"
    level_two = "level-2"
  }

  # Instance Storage Configs - empty by default to avoid creating example resources
  instance_storage_configs = {
    # S3
    CALL_RECORDINGS = {
      storage_type = "S3"

      s3_config = {
        bucket_name   = aws_s3_bucket.example.id
        bucket_prefix = "CALL_RECORDINGS"

        encryption_config = {
          encryption_type = "KMS"
          key_id          = aws_kms_key.example.arn
        }
      }
    }
    CHAT_TRANSCRIPTS = {
      storage_type = "S3"

      s3_config = {
        bucket_name   = aws_s3_bucket.example.id
        bucket_prefix = "CHAT_TRANSCRIPTS"

        encryption_config = {
          encryption_type = "KMS"
          key_id          = aws_kms_key.example.arn
        }
      }
    }
    SCHEDULED_REPORTS = {
      storage_type = "S3"

      s3_config = {
        bucket_name   = aws_s3_bucket.example.id
        bucket_prefix = "SCHEDULED_REPORTS"

        encryption_config = {
          encryption_type = "KMS"
          key_id          = aws_kms_key.example.arn
        }
      }
    }
  }
}

# S3
resource "aws_s3_bucket" "example" {
  bucket = "aws-connect-data-storage"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.example.id
  acl    = "private"
}

resource "aws_s3_bucket_logging" "example" {
  bucket        = aws_s3_bucket.example.id
  target_bucket = aws_s3_bucket.logging.id
  target_prefix = "${aws_s3_bucket.example.id}/logs/"
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket                  = aws_s3_bucket.example.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.example.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Logging
resource "aws_s3_bucket" "logging" {
  force_destroy = true
}

resource "aws_s3_bucket_acl" "logging" {
  bucket = aws_s3_bucket.logging.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_public_access_block" "logging" {
  bucket                  = aws_s3_bucket.logging.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logging" {
  bucket = aws_s3_bucket.logging.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "logging" {
  bucket = aws_s3_bucket.logging.id

  versioning_configuration {
    status = "Enabled"
  }
}

# KMS Key
resource "aws_kms_key" "example" {
  policy              = data.aws_iam_policy_document.example_key_policy.json
  enable_key_rotation = true
}

data "aws_iam_policy_document" "example_key_policy" {
  # Key Administrators
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Key Users
  statement {
    principals {
      type = "AWS"

      identifiers = [
        module.connect[0].instance.service_role
      ]
    }

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*"
    ]
    resources = ["*"]
  }
}
