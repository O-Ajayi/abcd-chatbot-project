# AWS Chatbot Service - Terraform Infrastructure

A comprehensive Terraform infrastructure for deploying a production-ready chatbot service on AWS using Lex V2, Lambda, Connect, Bedrock, Kendra, RDS, and DynamoDB.

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

### 2. Configure Variables

Copy the example variables file and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific configuration:

```hcl
aws_region  = "us-east-1"
project_name = "chatbot-service"
environment  = "dev"

# Set passwords and credentials
rds_password = "YourSecurePassword123!"
sns_subscription_emails = ["your-email@example.com"]

# Configure whether to create or use existing resources
create_vpc = true  # Set to false to use existing VPC
create_rds = true  # Set to false to use existing RDS
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Plan

```bash
terraform plan
```

### 5. Apply the Configuration

```bash
terraform apply
```

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

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review AWS service documentation
3. Check Terraform provider documentation
4. Open an issue in the repository

---

**Built with ❤️ using Terraform and AWS**
