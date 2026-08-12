output "aws_account_id" {
  description = "AWS account ID where QuickSight resources were created"
  value       = local.account_id
}
output "s3_bucket_name" {
  description = "S3 bucket containing sample QuickSight data"
  value       = aws_s3_bucket.quicksight_data.bucket
}
output "s3_sample_data_key" {
  description = "S3 object key for the sample sales CSV"
  value       = aws_s3_object.sales_csv.key
}
output "quicksight_data_source_arn" {
  description = "QuickSight S3 data source ARN"
  value       = aws_quicksight_data_source.sales_s3.arn
}
output "quicksight_data_set_arn" {
  description = "QuickSight sales dataset ARN"
  value       = aws_quicksight_data_set.sales.arn
}
output "quicksight_dashboard_arn" {
  description = "QuickSight dashboard ARN (null if create_dashboard is false)"
  value       = var.create_dashboard ? aws_quicksight_dashboard.sales[0].arn : null
}
output "quicksight_admin_user_arn" {
  description = "QuickSight admin user ARN"
  value       = aws_quicksight_user.admin.arn
}
output "quicksight_console_url" {
  description = "QuickSight console URL for the configured region"
  value       = "https://${var.aws_region}.quicksight.aws.amazon.com/sn/start"
}
output "quicksight_dashboard_url" {
  description = "Direct dashboard URL in the QuickSight console"
  value       = var.create_dashboard ? "https://${var.aws_region}.quicksight.aws.amazon.com/sn/account/${local.account_id}/dashboards/${local.dashboard_id}" : null
}
output "quicksight_iam_role_arn" {
  description = "IAM role QuickSight uses to read S3 data"
  value       = aws_iam_role.quicksight_s3.arn
}