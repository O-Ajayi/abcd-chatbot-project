data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
locals {
  account_id   = data.aws_caller_identity.current.account_id
  name_prefix  = "${var.project_name}-${var.env}"
  bucket_name  = "${local.name_prefix}-${random_id.bucket_suffix.hex}"
  data_set_id  = "${local.name_prefix}-sales"
  dashboard_id = "${local.name_prefix}-sales-dashboard"
}