# Running Bash Scripts with Terraform

This guide demonstrates different methods to execute bash scripts from Terraform while passing environment variables.

## Prerequisites

1. Make scripts executable:
   ```bash
   chmod +x terraform/scripts/*.sh
   ```

2. Ensure `null` provider is available (for `null_resource`):
   ```hcl
   terraform {
     required_providers {
       null = {
         source  = "hashicorp/null"
         version = "~> 3.0"
       }
     }
   }
   ```

## Method 1: Using `null_resource` with `local-exec` (Recommended)

This is the most common approach for running scripts during `terraform apply`.

### Example Usage

```hcl
resource "null_resource" "run_script" {
  triggers = {
    environment = var.environment
    script_hash = filebase64sha256("${path.root}/scripts/example-script.sh")
  }

  provisioner "local-exec" {
    command = "${path.root}/scripts/example-script.sh"
    
    environment = {
      TF_VAR_ENVIRONMENT  = var.environment
      TF_VAR_PROJECT_NAME = var.project_name
      TF_VAR_AWS_REGION   = var.aws_region
      CUSTOM_VAR          = "custom_value"
    }
  }
}
```

### Running with Environment-Specific Variables

```bash
# For dev environment
terraform apply -var-file=env/dev/terraform.tfvars

# For test environment
terraform apply -var-file=env/test/terraform.tfvars

# For prod environment
terraform apply -var-file=env/prod/terraform.tfvars
```

### Passing Additional Environment Variables

You can also pass environment variables directly via command line:

```bash
# Using -var flags
terraform apply \
  -var-file=env/dev/terraform.tfvars \
  -var="environment=dev" \
  -var="project_name=chatbot-service"

# Using environment variables (TF_VAR_ prefix)
export TF_VAR_ENVIRONMENT=dev
export TF_VAR_PROJECT_NAME=chatbot-service
terraform apply -var-file=env/dev/terraform.tfvars
```

## Method 2: Using `terraform_data` Resource (Terraform >= 1.4)

This is the modern recommended approach:

```hcl
resource "terraform_data" "run_script" {
  input = {
    environment  = var.environment
    project_name = var.project_name
  }

  provisioner "local-exec" {
    command = "${path.root}/scripts/example-script.sh"
    
    environment = {
      TF_VAR_ENVIRONMENT  = var.environment
      TF_VAR_PROJECT_NAME = var.project_name
    }
  }
}
```

## Method 3: Conditional Script Execution

Run scripts only under certain conditions:

```hcl
resource "null_resource" "run_script_conditionally" {
  count = var.environment == "prod" ? 1 : 0

  provisioner "local-exec" {
    command = "${path.root}/scripts/prod-script.sh"
    
    environment = {
      TF_VAR_ENVIRONMENT = var.environment
      RUN_MODE = "production"
    }
  }
}
```

## Method 4: Running Scripts After Resource Creation

Execute scripts after specific resources are created:

```hcl
resource "null_resource" "run_script_after_lambda" {
  depends_on = [module.lambda_functions]

  triggers = {
    lambda_arns = jsonencode(module.lambda_functions[0].lambda_arns)
  }

  provisioner "local-exec" {
    command = "${path.root}/scripts/post-deploy.sh"
    
    environment = {
      TF_VAR_ENVIRONMENT = var.environment
      LAMBDA_ARN_1 = module.lambda_functions[0].lambda_arns["chatbot-processor"]
      LAMBDA_ARN_2 = module.lambda_functions[0].lambda_arns["chatbot-analyzer"]
    }
  }
}
```

## Method 5: Using External Data Source

For scripts that return JSON data (runs during `terraform plan`):

```hcl
data "external" "script_output" {
  program = ["bash", "${path.root}/scripts/get-data.sh"]
  
  query = {
    environment  = var.environment
    project_name = var.project_name
  }
}

# Use the output
output "script_result" {
  value = data.external.script_output.result
}
```

Your script must output JSON:
```bash
#!/bin/bash
# scripts/get-data.sh
echo "{\"result\":\"success\",\"data\":\"value\"}"
```

## Best Practices

1. **Make scripts executable**: Always `chmod +x` your scripts
2. **Use triggers**: Add triggers to `null_resource` to control when scripts run
3. **Handle errors**: Use `set -e` in bash scripts to exit on errors
4. **Idempotency**: Design scripts to be idempotent (safe to run multiple times)
5. **Logging**: Add logging to scripts for debugging
6. **Path handling**: Use `${path.root}` for reliable path references

## Example: Complete Workflow

### 1. Create the script (`scripts/deploy.sh`)

```bash
#!/bin/bash
set -e

echo "Deploying to ${TF_VAR_ENVIRONMENT} environment"
echo "Project: ${TF_VAR_PROJECT_NAME}"
echo "Region: ${TF_VAR_AWS_REGION}"

# Your deployment logic here
```

### 2. Add to Terraform (`scripts.tf`)

```hcl
resource "null_resource" "deploy_script" {
  triggers = {
    environment = var.environment
  }

  provisioner "local-exec" {
    command = "${path.root}/scripts/deploy.sh"
    
    environment = {
      TF_VAR_ENVIRONMENT  = var.environment
      TF_VAR_PROJECT_NAME = var.project_name
      TF_VAR_AWS_REGION   = var.aws_region
    }
  }
}
```

### 3. Run Terraform

```bash
# Make script executable
chmod +x terraform/scripts/deploy.sh

# Apply with environment-specific variables
terraform apply -var-file=env/dev/terraform.tfvars
```

## Troubleshooting

1. **Script not found**: Ensure path is correct and uses `${path.root}`
2. **Permission denied**: Run `chmod +x` on the script
3. **Environment variables not set**: Check the `environment` block in `local-exec`
4. **Script runs every time**: Add proper `triggers` to control execution
5. **Dependencies not met**: Use `depends_on` to ensure resources exist first

## See Also

- [Terraform null_resource documentation](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource)
- [Terraform local-exec provisioner](https://www.terraform.io/docs/language/resources/provisioners/local-exec.html)
- [Terraform external data source](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/data_source)


