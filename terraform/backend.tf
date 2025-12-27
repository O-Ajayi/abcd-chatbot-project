# Backend configuration for Terraform state management
# This uses S3 for state storage and DynamoDB for state locking
# The backend is configured per environment using -backend-config flag or backend-config files

terraform {
  backend "s3" {
    # These values will be provided via -backend-config flags or backend-config files
    # Example: terraform init -backend-config=backend-dev.conf
    # bucket         = "your-terraform-state-bucket"
    # key            = "chatbot-service/dev/terraform.tfstate"
    # region         = "us-east-1"
    # dynamodb_table = "terraform-state-lock"
    # encrypt        = true
  }
}

