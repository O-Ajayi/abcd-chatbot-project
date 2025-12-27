output "table_names" {
  description = "DynamoDB table names"
  value = {
    for k, v in module.dynamodb_tables : k => v.dynamodb_table_name
  }
}

output "table_arns" {
  description = "DynamoDB table ARNs"
  value = {
    for k, v in module.dynamodb_tables : k => v.dynamodb_table_arn
  }
}

output "tables" {
  description = "Map of all DynamoDB tables"
  value = {
    for k, v in module.dynamodb_tables : k => {
      id  = v.dynamodb_table_id
      arn = v.dynamodb_table_arn
    }
  }
}

