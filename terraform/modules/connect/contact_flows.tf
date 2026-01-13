locals {
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
}
