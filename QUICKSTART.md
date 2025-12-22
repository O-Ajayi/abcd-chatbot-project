# Quick Start Guide

This guide will help you deploy the chatbot infrastructure quickly.

## Step 1: Prerequisites Check

```bash
# Check Terraform version
terraform version  # Should be >= 1.0

# Check AWS CLI
aws --version

# Configure AWS credentials
aws configure
```

## Step 2: Configure Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set at minimum:

```hcl
rds_password = "YourSecurePassword123!"
sns_subscription_emails = ["your-email@example.com"]
```

## Step 3: Initialize Terraform

```bash
terraform init
```

## Step 4: Review Plan

```bash
terraform plan
```

Review the plan to see what will be created. This may take a few minutes.

## Step 5: Deploy

```bash
terraform apply
```

Type `yes` when prompted. Deployment typically takes 15-30 minutes.

## Step 6: Get Outputs

```bash
# Get Lex Bot IDs for testing
terraform output lex_bot_id
terraform output lex_bot_alias_id

# Get Connect instance ID
terraform output connect_instance_id

# Get other important outputs
terraform output
```

## Step 7: Test the Chatbot

1. Open the UI:
```bash
cd ../ui
python3 -m http.server 8000
```

2. Navigate to `http://localhost:8000`

3. Enter the Bot ID and Alias ID from Step 6

4. Start chatting!

## Common Issues

### Issue: RDS password not set
**Solution**: Make sure `rds_password` is set in `terraform.tfvars`

### Issue: Email subscription not confirmed
**Solution**: Check your email and confirm the SNS subscription

### Issue: Lex bot not responding
**Solution**: 
- Verify Bot ID and Alias ID are correct
- Check Lambda function logs in CloudWatch
- Ensure the bot is published

### Issue: VPC creation fails
**Solution**: 
- Check your AWS account limits
- Verify you have permissions to create VPC resources
- Consider using existing VPC by setting `create_vpc = false`

## Next Steps

1. **Replace Lambda Code**: Update placeholder Lambda functions with your actual code
2. **Configure Bedrock Agent**: Use the IAM role ARN to create Bedrock agent via Console or module
3. **Add Kendra Data Sources**: Configure Kendra index with your data sources
4. **Customize Lex Intents**: Add more intents and utterances to your Lex bot
5. **Set Up Monitoring**: Configure additional CloudWatch alarms as needed

## Cost Estimation

Approximate monthly costs (varies by region and usage):
- VPC: ~$0 (NAT Gateway: ~$32/month)
- RDS (db.t3.micro): ~$15/month
- Lambda: Pay per request (very low for testing)
- Lex: Pay per request
- Connect: ~$0.018 per contact minute
- Kendra: ~$0.70 per hour for Developer Edition
- DynamoDB: Pay per request (very low for testing)
- CloudWatch: First 10GB free, then $0.50/GB

**Total estimated cost for testing**: ~$50-100/month

## Cleanup

To remove all resources:

```bash
terraform destroy
```

**Warning**: This permanently deletes all resources!

