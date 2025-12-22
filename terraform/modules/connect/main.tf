# AWS Connect Instance
resource "aws_connect_instance" "main" {
  identity_management_type = var.identity_management_type
  inbound_calls_enabled    = true
  outbound_calls_enabled   = true
  instance_alias           = "${var.project_name}-${var.environment}-${var.instance_alias}"

  tags = var.tags
}

# CloudWatch Log Group for Connect
resource "aws_cloudwatch_log_group" "connect" {
  name              = "/aws/connect/${aws_connect_instance.main.id}"
  retention_in_days = 7

  tags = var.tags
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  dashboard_name = var.cloudwatch_dashboard_name

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Connect", "ContactFlowErrors", { "stat" = "Sum" }],
            ["AWS/Connect", "ContactFlowFatalErrors", { "stat" = "Sum" }],
            [".", "ContactFlowErrors", { "stat" = "Average" }]
          ]
          period = 300
          stat   = "Sum"
          region = "us-east-1"
          title  = "Contact Flow Errors"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Connect", "ContactsInQueue", { "stat" = "Average" }],
            [".", "ContactsQueued", { "stat" = "Sum" }]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Contacts in Queue"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Connect", "ContactFlowTimeToAnswer", { "stat" = "Average" }],
            [".", "ContactFlowTimeToAnswer", { "stat" = "Maximum" }]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Time to Answer"
        }
      }
    ]
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "contact_flow_errors" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-contact-flow-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ContactFlowErrors"
  namespace           = "AWS/Connect"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "This metric monitors contact flow errors"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    InstanceId = aws_connect_instance.main.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "contacts_in_queue" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-contacts-in-queue"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ContactsInQueue"
  namespace           = "AWS/Connect"
  period              = 300
  statistic           = "Average"
  threshold           = 50
  alarm_description   = "This metric monitors contacts in queue"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    InstanceId = aws_connect_instance.main.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "time_to_answer" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-time-to-answer"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ContactFlowTimeToAnswer"
  namespace           = "AWS/Connect"
  period              = 300
  statistic           = "Average"
  threshold           = 30
  alarm_description   = "This metric monitors time to answer"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    InstanceId = aws_connect_instance.main.id
  }

  tags = var.tags
}

# Lex Bot Integration
resource "aws_connect_bot_association" "lex" {
  instance_id = aws_connect_instance.main.id
  lex_bot {
    name    = split(":", var.lex_bot_arn)[6]
    lex_region = split(":", var.lex_bot_arn)[3]
  }
}

