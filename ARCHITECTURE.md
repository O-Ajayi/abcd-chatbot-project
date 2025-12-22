# Architecture Documentation

## Overview

This Terraform infrastructure deploys a comprehensive chatbot service on AWS, integrating multiple AWS services to provide a production-ready conversational AI solution.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        User Interface                        │
│                    (Web UI / Mobile App)                     │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    AWS Lex V2 Bot                            │
│              (Natural Language Understanding)                │
└───────────────┬───────────────────────┬─────────────────────┘
                │                       │
                ▼                       ▼
┌──────────────────────┐    ┌──────────────────────────────┐
│   AWS Lambda         │    │    AWS Connect               │
│   Functions          │    │    (Contact Center)          │
│                      │    │                              │
│  - Processor         │    │  - Contact Flows             │
│  - Analyzer          │    │  - CloudWatch Monitoring     │
│  - Reviewer          │    │  - Alarms & Dashboard        │
└───────┬──────────────┘    └──────────────────────────────┘
        │
        ├─────────────────┬──────────────────┬──────────────┐
        │                 │                  │              │
        ▼                 ▼                  ▼              ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────┐
│  DynamoDB    │  │     RDS     │  │     SQS      │  │   SNS    │
│  Tables      │  │  (Postgres) │  │    Queue     │  │  Topic   │
│              │  │             │  │              │  │          │
│ - History    │  │ - Structured│  │ - Async      │  │ - Alerts │
│ - Reviews    │  │   Data      │  │   Processing │  │ - Notif. │
└──────────────┘  └──────────────┘  └──────────────┘  └──────────┘

┌─────────────────────────────────────────────────────────────┐
│              Amazon Bedrock Agent                            │
│         (Advanced AI with Foundation Models)                 │
│                                                              │
│  ┌────────────────────────────────────────────────────┐   │
│  │           Amazon Kendra                             │   │
│  │        (Intelligent Search)                         │   │
│  └────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. AWS Lex V2 Bot

**Purpose**: Handles natural language understanding and conversation management

**Features**:
- Multiple intents (Greeting, Help, Goodbye, etc.)
- Custom utterances
- Lambda fulfillment integration
- Multi-locale support

**Configuration**: Defined in `modules/lex-bot/`

### 2. AWS Lambda Functions

**Functions**:
- **chatbot-processor**: Processes incoming chatbot interactions
- **chatbot-analyzer**: Analyzes conversation data and patterns
- **chatbot-reviewer**: Reviews and processes conversation reviews

**Features**:
- VPC integration (optional)
- SQS event source mapping
- DynamoDB, RDS, SNS integration
- Environment variable configuration

**Configuration**: Defined in `modules/lambda-functions/`

### 3. AWS Connect

**Purpose**: Contact center integration with advanced routing

**Features**:
- Contact flows
- Lex bot integration
- CloudWatch monitoring
- Custom dashboards
- Alarms and notifications

**Configuration**: Defined in `modules/connect/`

### 4. Amazon Bedrock Agent

**Purpose**: Advanced AI agent using foundation models

**Features**:
- Foundation model integration (Claude, etc.)
- Knowledge base integration
- Lambda function tools
- DynamoDB integration

**Note**: IAM roles and Kendra index are created. The agent itself should be created using the [terraform-aws-bedrock module](https://github.com/aws-ia/terraform-aws-bedrock) or AWS Console.

**Configuration**: Defined in `modules/bedrock-agent/`

### 5. Amazon Kendra

**Purpose**: Intelligent search and knowledge base

**Features**:
- Developer or Enterprise edition
- Data source integration (configure separately)
- Query and retrieve APIs

**Configuration**: Defined in `modules/bedrock-agent/`

### 6. Amazon RDS

**Purpose**: Relational database for structured data

**Features**:
- PostgreSQL or MySQL support
- Automated backups
- Multi-AZ support (configurable)
- Encryption at rest

**Configuration**: Defined in `modules/rds/`

### 7. Amazon DynamoDB

**Tables**:
- **Chatbot-ConversationHistory**: Stores conversation history
  - Hash Key: `conversation_id`
- **Chatbot-Conversation-Reviewer**: Stores conversation reviews
  - Hash Key: `review_id`

**Features**:
- Pay-per-request billing
- Auto-scaling support
- Encryption at rest

### 8. Amazon SQS

**Purpose**: Asynchronous message processing

**Features**:
- Dead letter queue (DLQ)
- Lambda event source mapping
- Message retention (4 days)

### 9. Amazon SNS

**Purpose**: Notifications and alerts

**Features**:
- Email subscriptions
- CloudWatch alarm integration
- Multi-protocol support

### 10. Amazon CloudWatch

**Features**:
- Custom dashboard for Connect metrics
- Alarms for:
  - Contact flow errors
  - Contacts in queue
  - Time to answer
- Log groups for Lambda and Connect

### 11. VPC (Optional)

**Purpose**: Network isolation and security

**Features**:
- Public and private subnets
- NAT gateways
- Internet gateway
- Security groups for Lambda and RDS

**Configuration**: Defined in `modules/vpc/`

## Data Flow

### Standard Chat Flow

1. User sends message via UI
2. Message routed to Lex V2 bot
3. Lex processes intent and calls Lambda (chatbot-processor)
4. Lambda processes request:
   - Stores conversation in DynamoDB
   - Queries RDS if needed
   - May invoke Bedrock agent for complex queries
5. Response sent back through Lex
6. User receives response

### Review Processing Flow

1. Conversation review submitted
2. Stored in DynamoDB (Chatbot-Conversation-Reviewer)
3. Message sent to SQS queue
4. Lambda (chatbot-reviewer) processes from SQS
5. Analysis performed
6. Results stored and notifications sent via SNS

### Connect Integration Flow

1. Contact arrives in Connect
2. Contact flow determines routing
3. Lex bot invoked for automated responses
4. Metrics tracked in CloudWatch
5. Alarms triggered if thresholds exceeded
6. Notifications sent via SNS

## Security Considerations

### Network Security
- VPC with public/private subnet isolation
- Security groups restricting access
- RDS in private subnet
- Lambda in VPC (optional)

### IAM Security
- Least privilege IAM roles
- Service-specific policies
- No hardcoded credentials

### Data Security
- Encryption at rest (RDS, DynamoDB)
- Encryption in transit (TLS)
- Secrets management (RDS passwords)

### Access Control
- VPC-based network isolation
- IAM role-based access
- Security group rules

## Scalability

### Auto-scaling Components
- Lambda: Automatic scaling
- DynamoDB: Pay-per-request (auto-scales)
- RDS: Manual scaling (can be automated)

### Manual Scaling
- RDS instance class
- Lambda memory allocation
- VPC NAT gateway sizing

## Monitoring and Observability

### CloudWatch Metrics
- Lambda invocations, errors, duration
- DynamoDB read/write capacity
- RDS CPU, memory, connections
- Connect contact metrics
- SQS queue depth

### CloudWatch Logs
- Lambda function logs
- Connect logs
- Application logs

### CloudWatch Alarms
- Contact flow errors
- Queue depth
- Response time
- Error rates

### Dashboards
- Connect operational dashboard
- Custom metrics dashboard

## Cost Optimization

### Recommendations
1. Use pay-per-request DynamoDB for variable workloads
2. Right-size RDS instance
3. Use Lambda provisioned concurrency only if needed
4. Monitor and optimize NAT gateway usage
5. Use Kendra Developer Edition for testing
6. Set up cost alerts in AWS Budgets

## Disaster Recovery

### Backup Strategy
- RDS automated backups (7 days retention)
- DynamoDB point-in-time recovery (if enabled)
- Terraform state backup

### Recovery Procedures
1. Restore RDS from snapshot
2. Recreate infrastructure from Terraform
3. Restore DynamoDB from backup
4. Update DNS/endpoints

## Deployment Strategy

### Initial Deployment
1. Deploy VPC (if creating new)
2. Deploy RDS
3. Deploy DynamoDB tables
4. Deploy Lambda functions
5. Deploy Lex bot
6. Deploy Connect
7. Deploy Bedrock/Kendra
8. Configure integrations

### Updates
- Use Terraform plan to review changes
- Update Lambda code separately
- Lex bot updates require versioning
- RDS updates may require maintenance window

## Integration Points

### External Integrations
- Web UI (provided)
- Mobile apps (via API Gateway - not included)
- Third-party systems (via Lambda)
- CRM systems (via Connect)

### AWS Service Integrations
- Lex ↔ Lambda
- Lambda ↔ DynamoDB
- Lambda ↔ RDS
- Lambda ↔ SQS
- Lambda ↔ SNS
- Connect ↔ Lex
- Bedrock ↔ Kendra
- Bedrock ↔ Lambda
- CloudWatch ↔ All services

## Future Enhancements

### Potential Additions
- API Gateway for REST API
- Cognito for authentication
- CloudFront for CDN
- WAF for security
- X-Ray for tracing
- Step Functions for workflows
- EventBridge for event-driven architecture

