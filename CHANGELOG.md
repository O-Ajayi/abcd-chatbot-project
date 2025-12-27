# Changelog - Infrastructure Updates

## Latest Updates

### 1. DynamoDB Module Integration
- **Updated**: DynamoDB module now uses the official [terraform-aws-modules/terraform-aws-dynamodb-table](https://github.com/terraform-aws-modules/terraform-aws-dynamodb-table) module
- **Benefits**: 
  - Better feature support (autoscaling, point-in-time recovery, etc.)
  - Community-maintained and tested
  - Consistent with AWS best practices

### 2. Module Switches Added
- **Lambda Functions**: Added `create_lambda_functions` switch (default: `true`)
- **Lex Bot**: Added `create_lex_bot` switch (default: `true`)
- **Usage**: Set to `false` in `terraform.tfvars` to skip creation

### 3. Custom Security Groups Module
- **New Module**: `terraform/modules/security-groups/`
- **Security Groups Created**:
  - Lambda security group (with outbound access)
  - RDS security group (allows Lambda access)
  - Lex/Connect security group (optional)
  - Bedrock security group (optional)
- **Benefits**: Centralized security group management, better isolation

### 4. Placeholder ZIP Externalized
- **Location**: Moved from `terraform/modules/lambda-functions/placeholder.zip` to `packages/placeholder.zip`
- **Benefits**: 
  - Cleaner module structure
  - Shared placeholder across all functions
  - Easier to manage

### 5. Batch Build Scripts
- **New Scripts**:
  - `scripts/build-lambda-batch.sh` (Linux/Mac)
  - `scripts/build-lambda-batch.bat` (Windows)
- **Features**:
  - Automatically discovers all Lambda functions
  - Builds Python functions with RDS and DynamoDB dependencies
  - Detects RDS (psycopg2, pymysql) and DynamoDB (boto3) imports
  - Generates Terraform configuration snippet
  - Processes all functions in one command

### 6. Bedrock Module Integration
- **Updated**: Integrated official [terraform-aws-bedrock](https://github.com/aws-ia/terraform-aws-bedrock) module
- **Features**:
  - Full Bedrock agent support
  - Knowledge base integration
  - S3 data source support

## Migration Guide

### Using New Switches

In `terraform.tfvars`:
```hcl
# Skip Lambda functions
create_lambda_functions = false

# Skip Lex bot
create_lex_bot = false
```

### Using Batch Build Script

```bash
# Build all functions
./scripts/build-lambda-batch.sh

# Output will include Terraform configuration
```

### Using New Security Groups

Security groups are now automatically created by the `security-groups` module. No manual configuration needed.

### Using DynamoDB Module

The DynamoDB module now uses the terraform-aws-modules module. Configuration remains the same, but you get additional features like:
- Autoscaling support
- Point-in-time recovery
- Global tables
- Streams

## Breaking Changes

1. **Security Groups**: VPC module no longer creates security groups. They're now in the `security-groups` module.
2. **Module References**: Lambda and Lex modules now use `count`, so references must use `[0]` index.
3. **Placeholder Location**: Moved to `packages/` directory.

## Backward Compatibility

- Old configurations will still work after running `terraform init`
- Security groups are automatically migrated to the new module
- DynamoDB tables maintain the same structure

