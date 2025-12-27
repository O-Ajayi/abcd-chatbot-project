# AWS Chatbot Service - Terraform Infrastructure

A comprehensive Terraform infrastructure for deploying a production-ready chatbot service on AWS using Lex V2, Lambda, Connect, Bedrock, Kendra, RDS, and DynamoDB.

**Maintained by**: HUB DevOps Team ([HUBDevops@sparksoftcorp.com](mailto:HUBDevops@sparksoftcorp.com)) | Oluwasegun Ajayi ([Oluwasegun.Ajayi@sparksoftcorp.com](mailto:Oluwasegun.Ajayi@sparksoftcorp.com))

## 🏗️ Architecture Overview

This solution provides a complete chatbot infrastructure with:

- **AWS Lex V2 Bot** - Natural language understanding and conversation management
- **AWS Lambda Functions** - Serverless compute for processing chatbot interactions
- **AWS Connect** - Contact center integration with flows and monitoring
- **Amazon Bedrock Agent** - Advanced AI agent with foundation models
- **Amazon Kendra** - Intelligent search and knowledge base
- **Amazon RDS** - Relational database for structured data
- **Amazon DynamoDB** - NoSQL database for conversation history and reviews
- **Amazon SQS** - Message queue for asynchronous processing
- **Amazon SNS** - Notification service for alerts and monitoring
- **Amazon CloudWatch** - Monitoring, alarms, and dashboards

## 📋 Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- AWS account with necessary permissions
- Python 3.x (for Lambda functions)

## 🚀 Quick Start

### 1. Clone and Navigate

```bash
cd terraform
```

### 2. Set Up Backend (S3 and DynamoDB)

Before initializing Terraform, you need to set up the backend infrastructure:

#### Create S3 Bucket for State Storage

```bash
aws s3 mb s3://your-terraform-state-bucket --region us-east-1
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption \
  --bucket your-terraform-state-bucket \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

#### Create DynamoDB Table for State Locking

```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

#### Update Backend Configuration Files

Edit the backend configuration files in the `env/` directory with your actual S3 bucket name:

- `env/dev/backend.conf` - Development environment backend
- `env/test/backend.conf` - Test environment backend
- `env/prod/backend.conf` - Production environment backend

Each file should contain:

```hcl
bucket         = "your-actual-terraform-state-bucket"
key            = "chatbot-service/{environment}/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-state-lock"
encrypt        = true
```

### 3. Initialize Terraform for Your Environment

Choose your environment (dev, test, or prod) and initialize:

#### For DEV Environment:

```bash
terraform init -backend-config=env/dev/backend.conf
terraform plan -var-file=env/dev/terraform.tfvars
terraform apply -var-file=env/dev/terraform.tfvars
```

#### For TEST Environment:

```bash
terraform init -backend-config=env/test/backend.conf
terraform plan -var-file=env/test/terraform.tfvars
terraform apply -var-file=env/test/terraform.tfvars
```

#### For PROD Environment:

```bash
terraform init -backend-config=env/prod/backend.conf
terraform plan -var-file=env/prod/terraform.tfvars
terraform apply -var-file=env/prod/terraform.tfvars
```

### 4. Quick Reference: Environment Commands

All environment-specific files are organized in the `env/` directory. Use these commands based on your target environment:

**Dev Environment:**
```bash
terraform init -backend-config=env/dev/backend.conf
terraform plan -var-file=env/dev/terraform.tfvars
terraform apply -var-file=env/dev/terraform.tfvars
```

**Test Environment:**
```bash
terraform init -backend-config=env/test/backend.conf
terraform plan -var-file=env/test/terraform.tfvars
terraform apply -var-file=env/test/terraform.tfvars
```

**Prod Environment:**
```bash
terraform init -backend-config=env/prod/backend.conf
terraform plan -var-file=env/prod/terraform.tfvars
terraform apply -var-file=env/prod/terraform.tfvars
```

> **Note:** See `terraform/ENVIRONMENTS.md` for detailed environment management guide.

Type `yes` when prompted to create the resources.

### 6. Get Outputs

After deployment, retrieve important values:

```bash
terraform output lex_bot_id
terraform output lex_bot_alias_id
terraform output connect_instance_id
```

## 📁 Project Structure

```
terraform/
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output values
├── terraform.tfvars.example  # Example configuration file
└── modules/
    ├── vpc/                   # VPC module (optional)
    ├── rds/                   # RDS module (optional)
    ├── lambda-functions/     # Lambda functions module
    ├── lex-bot/              # Lex V2 bot module
    ├── connect/              # AWS Connect module
    └── bedrock-agent/        # Bedrock agent module

ui/
├── index.html                # Test UI application
└── README.md                # UI documentation
```

## ⚙️ Configuration Options

### Using Existing Resources

The infrastructure supports using existing AWS resources instead of creating new ones:

#### Use Existing VPC

```hcl
create_vpc = false
existing_vpc_id = "vpc-xxxxxxxxx"
existing_subnet_ids = ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"]
```

#### Use Existing RDS

```hcl
create_rds = false
existing_rds_endpoint = "chatbot-db.xxxxxxxxx.us-east-1.rds.amazonaws.com:5432"
```

### Lambda Functions Configuration

Lambda functions are created from a list, making it easy to add or modify functions:

```hcl
lambda_functions = [
  {
    name        = "chatbot-processor"
    description = "Processes chatbot interactions"
    handler     = "index.handler"
    runtime     = "python3.11"
    timeout     = 30
    memory_size = 256
    environment_variables = {
      ENV = "dev"
    }
  },
  # Add more functions as needed
]
```

### DynamoDB Tables Configuration

DynamoDB tables are also configured as a list:

```hcl
dynamodb_tables = [
  {
    name           = "Chatbot-ConversationHistory"
    hash_key       = "conversation_id"
    billing_mode   = "PAY_PER_REQUEST"
    attributes = [
      {
        name = "conversation_id"
        type = "S"
      }
    ]
  },
  # Add more tables as needed
]
```

### Lex Bot Intents

Customize Lex bot intents and utterances:

```hcl
lex_sample_intents = [
  {
    name        = "GreetingIntent"
    description = "Handles greeting messages"
    utterances  = ["Hello", "Hi", "Hey", "Good morning"]
    slots       = []
  },
  # Add more intents
]
```

## 🧪 Testing the Chatbot

### Using the Angular UI Application

The project includes a complete Angular frontend application with a Node.js backend proxy service for testing your deployed chatbot.

#### Quick Setup

1. **Set up the UI** (first time only):

```bash
cd ui
./setup.sh
# Or manually:
# cd backend && npm install
# cd ../angular-ui && npm install
```

2. **Configure AWS Credentials**:

The backend service needs AWS credentials to communicate with Lex V2. You can configure them in one of these ways:

```bash
# Option 1: Environment variables
export AWS_ACCESS_KEY_ID=your-access-key-id
export AWS_SECRET_ACCESS_KEY=your-secret-access-key
export AWS_REGION=us-east-1

# Option 2: AWS credentials file (~/.aws/credentials)
# Option 3: IAM role (if running on EC2)
```

3. **Get Your Bot Information**:

```bash
cd terraform
terraform output lex_bot_id
terraform output lex_bot_alias_id
```

4. **Start the Backend Service** (Terminal 1):

```bash
cd ui/backend
npm start
# Server runs on http://localhost:3000
```

5. **Start the Angular Frontend** (Terminal 2):

```bash
cd ui/angular-ui
npm start
# Application runs on http://localhost:4200
```

6. **Test the Chatbot**:

- Open `http://localhost:4200` in your browser
- Enter your Bot ID and Bot Alias ID from step 3
- Configure Locale ID (default: `en_US`) and Region (default: `us-east-1`)
- Start chatting!

#### UI Features

- **Modern Angular UI**: Clean, responsive design
- **Real-time Chat**: Send and receive messages instantly
- **Configuration Management**: Save bot settings in browser
- **Session Management**: Automatic session handling
- **Typing Indicators**: Visual feedback during processing
- **Error Handling**: User-friendly error messages

For detailed information, see [ui/README.md](ui/README.md).

## 📊 Monitoring and Alerts

### CloudWatch Dashboard

A CloudWatch dashboard is automatically created with metrics for:
- Contact flow errors
- Contacts in queue
- Time to answer

Access it via the AWS Console or use the output:

```bash
terraform output cloudwatch_dashboard_url
```

### CloudWatch Alarms

The following alarms are configured (if enabled):
- Contact flow errors threshold
- Contacts in queue threshold
- Time to answer threshold

Alarms send notifications to the configured SNS topic.

### SNS Notifications

Configure email subscriptions in `terraform.tfvars`:

```hcl
sns_subscription_emails = ["admin@example.com", "devops@example.com"]
```

After deployment, confirm the email subscriptions from your inbox.

## 🔧 Customization

### Adding Lambda Functions

1. Add function configuration to `terraform.tfvars`:

```hcl
lambda_functions = [
  # ... existing functions ...
  {
    name        = "new-function"
    description = "New function description"
    handler     = "index.handler"
    runtime     = "python3.11"
    timeout     = 30
    memory_size = 256
    environment_variables = {}
  }
]
```

2. Update the Lambda function code in `modules/lambda-functions/`

3. Apply changes:

```bash
terraform apply
```

### Adding DynamoDB Tables

1. Add table configuration to `terraform.tfvars`:

```hcl
dynamodb_tables = [
  # ... existing tables ...
  {
    name           = "NewTable"
    hash_key       = "id"
    billing_mode   = "PAY_PER_REQUEST"
    attributes = [
      {
        name = "id"
        type = "S"
      }
    ]
  }
]
```

2. Apply changes:

```bash
terraform apply
```

## 🔐 Security Considerations

1. **RDS Password**: Use a strong password and consider using AWS Secrets Manager
2. **IAM Roles**: Review and restrict IAM policies as needed
3. **VPC Configuration**: Ensure proper security group rules
4. **Encryption**: Enable encryption at rest for RDS and DynamoDB
5. **Network**: Use private subnets for RDS and Lambda when possible

## 🧹 Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will delete all resources created by this configuration. Make sure to backup any important data first.

## 📚 Module Details

### VPC Module

Creates a VPC with public and private subnets, NAT gateways, and security groups.

**Outputs:**
- `vpc_id`
- `subnet_ids`
- `lambda_security_group_id`
- `rds_security_group_id`

### RDS Module

Creates an RDS instance with configurable engine, version, and instance class.

**Outputs:**
- `rds_endpoint`
- `rds_address`
- `rds_port`

### Lambda Functions Module

Creates Lambda functions from a list configuration with VPC support and SQS integration.

**Outputs:**
- `lambda_names`
- `lambda_arns`
- `lambda_role_arn`

### Lex Bot Module

Creates a Lex V2 bot with intents, utterances, and Lambda integration.

**Outputs:**
- `bot_id`
- `bot_arn`
- `bot_alias_id`

### Connect Module

Creates an AWS Connect instance with CloudWatch monitoring and Lex integration.

**Outputs:**
- `instance_id`
- `instance_arn`
- `dashboard_url`

### Bedrock Agent Module

Sets up IAM roles and Kendra index for Bedrock agent. **Note**: The actual Bedrock agent should be created using the [terraform-aws-bedrock module](https://github.com/aws-ia/terraform-aws-bedrock) or via AWS Console.

**Outputs:**
- `agent_role_arn`
- `kendra_index_id`
- `kendra_index_arn`

## 🐛 Troubleshooting

### Lex Bot Not Responding

1. Verify Bot ID and Alias ID are correct
2. Check Lambda function permissions
3. Review CloudWatch logs for errors
4. Ensure the bot is published to the correct alias

### Lambda Function Errors

1. Check CloudWatch Logs for the specific function
2. Verify IAM permissions
3. Test function code locally
4. Check VPC configuration if using VPC

### RDS Connection Issues

1. Verify security group rules allow Lambda access
2. Check RDS endpoint is correct
3. Verify credentials
4. Ensure RDS is in the same VPC as Lambda

### Connect Integration Issues

1. Verify Lex bot is associated correctly
2. Check IAM roles and permissions
3. Review Connect contact flows
4. Check CloudWatch alarms for errors

## 📖 Additional Resources

- [AWS Lex V2 Documentation](https://docs.aws.amazon.com/lexv2/)
- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [AWS Connect Documentation](https://docs.aws.amazon.com/connect/)
- [Amazon Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License.

## ⚠️ Important Notes

1. **Costs**: This infrastructure creates multiple AWS resources that incur costs. Monitor your AWS billing.
2. **Bedrock Agent**: The Bedrock agent requires manual creation or use of the terraform-aws-bedrock module. IAM roles are provided.
3. **Lambda Code**: Placeholder Lambda functions are created. Replace with your actual code.
4. **Kendra**: Kendra indexes can take time to create and index content.
5. **Connect**: AWS Connect instances are region-specific and may have availability limitations.

## 🆘 Support & Maintenance

For issues, questions, or support requests related to the AWS Chatbot Service:

**Primary Contacts:**
- **HUB DevOps Team**: [HUBDevops@sparksoftcorp.com](mailto:HUBDevops@sparksoftcorp.com)
- **Oluwasegun Ajayi**: [Oluwasegun.Ajayi@sparksoftcorp.com](mailto:Oluwasegun.Ajayi@sparksoftcorp.com)

**Before contacting support:**
1. Check the troubleshooting section below
2. Review AWS service documentation
3. Check Terraform provider documentation
4. Review the `ENVIRONMENTS.md` guide for environment-specific issues
5. See [SUPPORT.md](../SUPPORT.md) for detailed support process

**Support Process:**
- For urgent production issues, contact the maintainers directly
- For feature requests or general questions, email the HUB DevOps team
- Include environment details (dev/test/prod) and error messages when reporting issues
- See [SUPPORT.md](../SUPPORT.md) for complete support guidelines

---

## 👥 Maintainers

This project is maintained by:
- **HUB DevOps Team** - [HUBDevops@sparksoftcorp.com](mailto:HUBDevops@sparksoftcorp.com)
- **Oluwasegun Ajayi** - [Oluwasegun.Ajayi@sparksoftcorp.com](mailto:Oluwasegun.Ajayi@sparksoftcorp.com)

---

**Built with ❤️ using Terraform and AWS**
