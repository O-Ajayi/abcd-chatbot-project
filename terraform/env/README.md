# Environment-Specific Configuration

This directory contains environment-specific Terraform configurations for dev, test, and prod environments.

## Directory Structure

```
env/
├── dev/
│   ├── backend.conf          # S3 backend configuration for dev
│   └── terraform.tfvars       # Terraform variables for dev
├── test/
│   ├── backend.conf          # S3 backend configuration for test
│   └── terraform.tfvars      # Terraform variables for test
└── prod/
    ├── backend.conf          # S3 backend configuration for prod
    └── terraform.tfvars      # Terraform variables for prod
```

## Usage

### Initialize and Deploy to an Environment

From the `terraform/` directory:

**Dev:**
```bash
terraform init -backend-config=env/dev/backend.conf
terraform plan -var-file=env/dev/terraform.tfvars
terraform apply -var-file=env/dev/terraform.tfvars
```

**Test:**
```bash
terraform init -backend-config=env/test/backend.conf
terraform plan -var-file=env/test/terraform.tfvars
terraform apply -var-file=env/test/terraform.tfvars
```

**Prod:**
```bash
terraform init -backend-config=env/prod/backend.conf
terraform plan -var-file=env/prod/terraform.tfvars
terraform apply -var-file=env/prod/terraform.tfvars
```

## Configuration Files

### backend.conf

Each environment has its own backend configuration file that specifies:
- S3 bucket for state storage
- State file key (path within bucket)
- DynamoDB table for state locking
- AWS region

**Important:** Update the `bucket` value in each `backend.conf` file with your actual S3 bucket name before initializing.

### terraform.tfvars

Each environment has its own variables file containing:
- AWS region and project settings
- Resource configurations (VPC, RDS, Lambda, etc.)
- Environment-specific tags
- Resource sizing and capacity

**Important:** Update sensitive values like passwords and email addresses before deploying.

## Switching Between Environments

When switching between environments, use `-reconfigure`:

```bash
# From dev to test
terraform init -reconfigure -backend-config=env/test/backend.conf

# From test to prod
terraform init -reconfigure -backend-config=env/prod/backend.conf
```

## Best Practices

1. **Never commit secrets**: Use AWS Secrets Manager or environment variables for sensitive data
2. **Review before applying**: Always run `terraform plan` before `terraform apply`
3. **Use separate AWS accounts**: Consider using separate AWS accounts for prod
4. **Version control**: Keep these files in version control but use `.gitignore` for sensitive values
5. **Backup state files**: S3 versioning provides automatic backups

