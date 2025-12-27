# Lambda Functions

This directory contains the source code for the Lambda functions used in the chatbot service.

## Functions

### 1. chatbot-processor
**Purpose**: Processes chatbot interactions and stores them in RDS

**Connections**:
- RDS PostgreSQL/MySQL database

**Responsibilities**:
- Receive chatbot interaction events from Lex
- Store interactions in RDS database
- Process intents and generate responses
- Update interaction records with responses

**Dependencies**:
- `psycopg2-binary` - PostgreSQL adapter

### 2. chatbot-analyzer
**Purpose**: Analyzes conversation data from RDS

**Connections**:
- RDS PostgreSQL/MySQL database

**Responsibilities**:
- Analyze conversation patterns
- Generate session summaries
- Calculate intent distributions
- Perform sentiment analysis (placeholder)

**Dependencies**:
- `psycopg2-binary` - PostgreSQL adapter

### 3. chatbot-reviewer
**Purpose**: Reviews conversations and stores reviews in DynamoDB and RDS

**Connections**:
- DynamoDB tables (Chatbot-ConversationHistory, Chatbot-Conversation-Reviewer)
- RDS PostgreSQL/MySQL database
- SQS queue (event source)

**Responsibilities**:
- Process review messages from SQS
- Store reviews in DynamoDB
- Retrieve conversation history from DynamoDB
- Store review summaries in RDS
- Handle batch processing from SQS

**Dependencies**:
- `psycopg2-binary` - PostgreSQL adapter
- `boto3` - AWS SDK for Python

## Development

### Prerequisites
- Python 3.11+
- pip

### Local Development

1. **Set up virtual environment** (optional but recommended):
```bash
cd chatbot-processor  # or chatbot-analyzer, chatbot-reviewer
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. **Install dependencies**:
```bash
pip install -r requirements.txt
```

3. **Test locally**:
```python
# Create a test event
event = {
    "sessionId": "test-session-123",
    "inputText": "Hello",
    "intent": "GreetingIntent",
    "slots": {}
}

# Import and test
from index import handler
result = handler(event, None)
print(result)
```

## Building and Packaging

### Using the Build Script

The project includes build scripts to package Lambda functions with their dependencies:

**Linux/Mac**:
```bash
# Build all functions
./scripts/build-lambda.sh

# Build specific function
./scripts/build-lambda.sh chatbot-processor
```

**Windows**:
```powershell
# Build all functions
.\scripts\build-lambda.ps1

# Build specific function
.\scripts\build-lambda.ps1 -Functions chatbot-processor
```

### Manual Build

1. **Install dependencies**:
```bash
pip install -r requirements.txt -t .
```

2. **Create deployment package**:
```bash
zip -r ../packages/chatbot-processor.zip .
```

### Package Structure

The build script creates packages in the `packages/` directory:
```
packages/
├── chatbot-processor.zip
├── chatbot-analyzer.zip
└── chatbot-reviewer.zip
```

## Database Schema

### RDS Tables

The Lambda functions expect the following tables in your RDS database:

```sql
-- Chatbot interactions table
CREATE TABLE IF NOT EXISTS chatbot_interactions (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL,
    input_text TEXT,
    intent VARCHAR(100),
    slots JSONB,
    response_text TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Conversation reviews table
CREATE TABLE IF NOT EXISTS conversation_reviews (
    review_id VARCHAR(255) PRIMARY KEY,
    conversation_id VARCHAR(255) NOT NULL,
    review_text TEXT,
    rating INTEGER,
    conversation_data JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_interactions_session_id ON chatbot_interactions(session_id);
CREATE INDEX IF NOT EXISTS idx_interactions_created_at ON chatbot_interactions(created_at);
CREATE INDEX IF NOT EXISTS idx_reviews_conversation_id ON conversation_reviews(conversation_id);
```

**Note**: Run these SQL commands in your RDS database after deployment.

## Environment Variables

The Lambda functions use the following environment variables:

### Common Variables
- `RDS_ENDPOINT` - RDS endpoint (host:port)
- `RDS_USERNAME` - RDS username
- `RDS_PASSWORD` - RDS password
- `RDS_DATABASE_NAME` - RDS database name
- `SNS_TOPIC_ARN` - SNS topic ARN for notifications

### Function-Specific Variables

**chatbot-reviewer**:
- `DYNAMODB_HISTORY_TABLE` - DynamoDB table name for conversation history
- `DYNAMODB_REVIEWER_TABLE` - DynamoDB table name for reviews
- `SQS_QUEUE_URL` - SQS queue URL (for event source mapping)

**All functions**:
- `KENDRA_DATA_SOURCE_BUCKET` - S3 bucket for Kendra data source
- `LEX_BOT_LOGS_BUCKET` - S3 bucket for Lex bot logs

## Deployment

### Using Terraform

1. **Build Lambda packages**:
```bash
./scripts/build-lambda.sh
```

2. **Update Terraform variables**:
```hcl
lambda_package_paths = {
  "chatbot-processor" = "../packages/chatbot-processor.zip"
  "chatbot-analyzer" = "../packages/chatbot-analyzer.zip"
  "chatbot-reviewer" = "../packages/chatbot-reviewer.zip"
}
```

3. **Deploy with Terraform**:
```bash
cd terraform
terraform apply
```

### Manual Deployment

1. **Build packages** (see above)

2. **Upload to S3** (optional):
```bash
aws s3 cp packages/chatbot-processor.zip s3://your-bucket/lambda/
```

3. **Update Lambda function**:
```bash
aws lambda update-function-code \
  --function-name chatbot-service-dev-chatbot-processor \
  --zip-file fileb://packages/chatbot-processor.zip
```

## Testing

### Unit Testing

Create test files for each function:

```python
# test_chatbot_processor.py
import unittest
from index import handler

class TestChatbotProcessor(unittest.TestCase):
    def test_handler(self):
        event = {
            "sessionId": "test-123",
            "inputText": "Hello",
            "intent": "GreetingIntent",
            "slots": {}
        }
        result = handler(event, None)
        self.assertEqual(result['statusCode'], 200)
```

Run tests:
```bash
python -m pytest test_chatbot_processor.py
```

### Integration Testing

Test with actual AWS resources:
1. Deploy infrastructure
2. Invoke Lambda function via AWS Console or CLI
3. Check CloudWatch logs
4. Verify database records

## Monitoring

### CloudWatch Logs

Each Lambda function automatically logs to CloudWatch:
- Function name: `/aws/lambda/chatbot-service-{env}-{function-name}`
- Log level: INFO, ERROR

### Metrics

Monitor:
- Invocations
- Duration
- Errors
- Throttles
- Concurrent executions

## Troubleshooting

### Connection Issues

**RDS Connection Errors**:
- Verify RDS endpoint is correct
- Check security group allows Lambda access
- Verify credentials in environment variables
- Check VPC configuration if Lambda is in VPC

**DynamoDB Connection Errors**:
- Verify table names in environment variables
- Check IAM permissions
- Verify table exists

### Performance Issues

- **Cold starts**: Consider provisioned concurrency
- **Timeout**: Increase timeout in Terraform configuration
- **Memory**: Increase memory allocation
- **Connection pooling**: Already implemented in code

### Common Errors

1. **"ModuleNotFoundError"**: Dependencies not included in package
   - Rebuild package with dependencies
   - Check requirements.txt

2. **"Access Denied"**: IAM permissions issue
   - Check Lambda execution role
   - Verify resource ARNs

3. **"Connection timeout"**: Network/VPC issue
   - Check security groups
   - Verify VPC configuration
   - Check NAT gateway (if Lambda in private subnet)

## Best Practices

1. **Connection Pooling**: Use connection pools for RDS (already implemented)
2. **Error Handling**: Always handle exceptions gracefully
3. **Logging**: Log important events and errors
4. **Environment Variables**: Use environment variables for configuration
5. **Idempotency**: Design functions to be idempotent
6. **Timeouts**: Set appropriate timeouts
7. **Memory**: Right-size memory allocation

## Security

1. **Credentials**: Never hardcode credentials
2. **Secrets**: Use AWS Secrets Manager for sensitive data
3. **VPC**: Use VPC for RDS access when possible
4. **IAM**: Follow principle of least privilege
5. **Encryption**: Enable encryption at rest and in transit

