# Environment-Specific Configuration Guide

This document explains how to manage multiple environments (dev, test, prod) for the chatbot service infrastructure.

## Overview

The Terraform configuration supports three environments:
- **dev** - Development environment with minimal resources
- **test** - Testing environment with moderate resources
- **prod** - Production environment with optimized resources

## Backend Configuration

Each environment uses a separate Terraform state file stored in S3, with DynamoDB for state locking.

### Backend Files

All environment-specific files are organized in the `env/` directory:

- `env/dev/backend.conf` - Backend configuration for dev environment
- `env/dev/terraform.tfvars` - Variables for dev environment
- `env/test/backend.conf` - Backend configuration for test environment
- `env/test/terraform.tfvars` - Variables for test environment
- `env/prod/backend.conf` - Backend configuration for prod environment
- `env/prod/terraform.tfvars` - Variables for prod environment

### Setting Up Backend

1. **Create S3 Bucket** (one-time setup):
   ```bash
   aws s3 mb s3://your-terraform-state-bucket --region us-east-1
   aws s3api put-bucket-versioning \
     --bucket your-terraform-state-bucket \
     --versioning-configuration Status=Enabled
   ```

2. **Create DynamoDB Table** (one-time setup):
   ```bash
   aws dynamodb create-table \
     --table-name terraform-state-lock \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST
   ```

3. **Update Backend Config Files**:
   Edit each `env/{env}/backend.conf` file with your actual bucket name.

## Environment-Specific Variables

### Dev Environment (`env/dev/terraform.tfvars`)

- **VPC CIDR**: `10.0.0.0/16`
- **RDS Instance**: `db.t3.micro`
- **Lambda Memory**: 256-512 MB
- **DynamoDB**: PAY_PER_REQUEST
- **Kendra Edition**: DEVELOPER_EDITION
- **Log Retention**: 30 days

### Test Environment (`env/test/terraform.tfvars`)

- **VPC CIDR**: `10.1.0.0/16`
- **RDS Instance**: `db.t3.small`
- **Lambda Memory**: 512-1024 MB
- **DynamoDB**: PAY_PER_REQUEST
- **Kendra Edition**: DEVELOPER_EDITION
- **Log Retention**: 60 days
- **Availability Zones**: 3 zones for high availability

### Prod Environment (`env/prod/terraform.tfvars`)

- **VPC CIDR**: `10.2.0.0/16`
- **RDS Instance**: `db.t3.medium`
- **Lambda Memory**: 1024-2048 MB
- **DynamoDB**: PROVISIONED (with capacity planning)
- **Kendra Edition**: ENTERPRISE_EDITION
- **Log Retention**: 90 days
- **Availability Zones**: 3 zones for high availability
- **SQS Max Receive Count**: 5 (higher retry limit)

## Usage Examples

### Deploy to Dev

```bash
# Initialize with dev backend
terraform init -backend-config=env/dev/backend.conf

# Plan changes
terraform plan -var-file=env/dev/terraform.tfvars

# Apply changes
terraform apply -var-file=env/dev/terraform.tfvars
```

### Deploy to Test

```bash
# Initialize with test backend
terraform init -backend-config=env/test/backend.conf

# Plan changes
terraform plan -var-file=env/test/terraform.tfvars

# Apply changes
terraform apply -var-file=env/test/terraform.tfvars
```

### Deploy to Prod

```bash
# Initialize with prod backend
terraform init -backend-config=env/prod/backend.conf

# Plan changes (always review carefully!)
terraform plan -var-file=env/prod/terraform.tfvars

# Apply changes (use -auto-approve only if using CI/CD)
terraform apply -var-file=env/prod/terraform.tfvars
```

## Switching Between Environments

When switching between environments, you need to re-initialize Terraform:

```bash
# Switch from dev to test
terraform init -reconfigure -backend-config=env/test/backend.conf

# Switch from test to prod
terraform init -reconfigure -backend-config=env/prod/backend.conf
```

## State Management

Each environment maintains its own state file:
- Dev: `chatbot-service/dev/terraform.tfstate`
- Test: `chatbot-service/test/terraform.tfstate`
- Prod: `chatbot-service/prod/terraform.tfstate`

State files are:
- Stored in S3 with versioning enabled
- Encrypted at rest
- Locked using DynamoDB to prevent concurrent modifications

## Best Practices

1. **Never commit secrets**: Use AWS Secrets Manager or environment variables for sensitive data
2. **Review plans carefully**: Especially for prod environment
3. **Use workspaces**: Consider Terraform workspaces for additional isolation
4. **Backup state files**: S3 versioning provides automatic backups
5. **Tag resources**: All resources are tagged with environment for cost tracking
6. **Separate AWS accounts**: For production, consider using separate AWS accounts

## Troubleshooting

### Backend Initialization Errors

If you see errors during `terraform init`:
1. Verify S3 bucket exists and is accessible
2. Verify DynamoDB table exists
3. Check AWS credentials and permissions
4. Ensure backend config file path is correct

### State Lock Issues

If state is locked:
```bash
# Check who has the lock
aws dynamodb get-item \
  --table-name terraform-state-lock \
  --key '{"LockID":{"S":"your-state-key"}}'

# Force unlock (use with caution!)
terraform force-unlock <LOCK_ID>
```

### Provider Version Conflicts

If you see provider version errors:
```bash
# Update provider versions
terraform init -upgrade
```

