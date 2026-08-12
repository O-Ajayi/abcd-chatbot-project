variable "aws_region" {
  description = "AWS region for QuickSight and S3 resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used for resource names"
  type        = string
  default     = "hub-quicksight"
}

variable "env" {
  description = "Environment label"
  type        = string
  default     = "dev"
}

variable "admin_email" {
  description = "QuickSight admin user email and subscription notification address"
  type        = string
}

variable "quicksight_account_name" {
  description = "Display name for the QuickSight account subscription"
  type        = string
  default     = "hub-quicksight-demo"
}

variable "enable_quicksight_subscription" {
  description = "Create a QuickSight account subscription. Set false if QuickSight is already enabled in the account"
  type        = bool
  default     = false
}

variable "quicksight_edition" {
  description = "QuickSight edition: STANDARD, ENTERPRISE, or ENTERPRISE_AND_Q"
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "ENTERPRISE", "ENTERPRISE_AND_Q"], var.quicksight_edition)
    error_message = "quicksight_edition must be STANDARD, ENTERPRISE, or ENTERPRISE_AND_Q."
  }
}

variable "authentication_method" {
  description = "QuickSight authentication method"
  type        = string
  default     = "IAM_AND_QUICKSIGHT"

  validation {
    condition     = contains(["IAM_AND_QUICKSIGHT", "IAM_ONLY", "IAM_IDENTITY_CENTER", "ACTIVE_DIRECTORY"], var.authentication_method)
    error_message = "authentication_method must be a supported QuickSight authentication method."
  }
}

variable "create_dashboard" {
  description = "Create a sample QuickSight dashboard from the sales dataset"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags applied to supported resources"
  type        = map(string)
  default     = {}
}
