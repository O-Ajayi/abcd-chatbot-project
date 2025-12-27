# Build Scripts

This directory contains scripts for building and packaging Lambda functions.

## build-lambda-batch.sh / build-lambda-batch.bat

Batch build scripts that process all Lambda functions in the `lambda-functions/` directory. These scripts are designed for Python Lambda functions that connect to RDS and read from DynamoDB tables.

### Features

- **Automatic Discovery**: Finds all Lambda functions in `lambda-functions/` directory
- **Dependency Management**: Installs Python dependencies from `requirements.txt`
- **RDS/DynamoDB Detection**: Verifies RDS and DynamoDB imports in code
- **Batch Processing**: Builds all functions in one command
- **Package Generation**: Creates ZIP files in `packages/` directory
- **Terraform Integration**: Generates `lambda_package_paths` configuration

### Usage

**Linux/Mac:**
```bash
# Build all Lambda functions
./scripts/build-lambda-batch.sh

# Build specific function(s)
./scripts/build-lambda-batch.sh chatbot-processor chatbot-analyzer
```

**Windows:**
```batch
REM Build all Lambda functions
.\scripts\build-lambda-batch.bat
```

### Requirements

- Python 3.11+
- pip
- zip (Linux/Mac) or PowerShell (Windows)

### What It Does

1. Scans `lambda-functions/` directory for Python functions
2. For each function with `index.py`:
   - Copies source code to build directory
   - Installs dependencies from `requirements.txt`
   - Detects RDS (psycopg2, pymysql) and DynamoDB (boto3) imports
   - Creates deployment ZIP package
   - Outputs package to `packages/` directory

3. Generates Terraform configuration snippet

### Output

Packages are created in `packages/` directory:
```
packages/
├── chatbot-processor.zip
├── chatbot-analyzer.zip
└── chatbot-reviewer.zip
```

### Using Built Packages

After building, update `terraform/terraform.tfvars`:

```hcl
lambda_package_paths = {
  "chatbot-processor" = "../packages/chatbot-processor.zip"
  "chatbot-analyzer" = "../packages/chatbot-analyzer.zip"
  "chatbot-reviewer" = "../packages/chatbot-reviewer.zip"
}
```

Then deploy:
```bash
cd terraform
terraform apply
```

## build-lambda.sh / build-lambda.ps1

Individual function build scripts (see previous documentation).
