# DynamoDB Tables using terraform-aws-modules/terraform-aws-dynamodb-table
# Reference: https://github.com/terraform-aws-modules/terraform-aws-dynamodb-table
module "dynamodb_tables" {
  source   = "terraform-aws-modules/dynamodb-table/aws"
  version  = "~> 5.0"
  for_each = {
    for idx, table in var.tables : table.name => table
  }

  name     = "${var.project_name}-${each.value.name}"
  hash_key = each.value.hash_key
  range_key = each.value.range_key

  attributes = each.value.attributes

  billing_mode   = each.value.billing_mode
  read_capacity  = each.value.billing_mode == "PROVISIONED" ? each.value.read_capacity : null
  write_capacity = each.value.billing_mode == "PROVISIONED" ? each.value.write_capacity : null

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${each.value.name}"
    }
  )
}

