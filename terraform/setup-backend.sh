#!/bin/bash

# Script to set up Terraform backend (S3 bucket and DynamoDB table)
# Usage: ./setup-backend.sh <bucket-name> <region>

set -e

BUCKET_NAME=${1:-"terraform-state-bucket-chatbot"}
REGION=${2:-"us-east-1"}
DYNAMODB_TABLE="terraform-state-lock"

echo "Setting up Terraform backend..."
echo "S3 Bucket: ${BUCKET_NAME}"
echo "Region: ${REGION}"
echo "DynamoDB Table: ${DYNAMODB_TABLE}"
echo ""

# Create S3 bucket
echo "Creating S3 bucket..."
if aws s3 ls "s3://${BUCKET_NAME}" 2>&1 | grep -q 'NoSuchBucket'; then
    aws s3 mb "s3://${BUCKET_NAME}" --region "${REGION}"
    echo "✓ S3 bucket created"
else
    echo "✓ S3 bucket already exists"
fi

# Enable versioning
echo "Enabling S3 bucket versioning..."
aws s3api put-bucket-versioning \
    --bucket "${BUCKET_NAME}" \
    --versioning-configuration Status=Enabled \
    --region "${REGION}"
echo "✓ Versioning enabled"

# Enable encryption
echo "Enabling S3 bucket encryption..."
aws s3api put-bucket-encryption \
    --bucket "${BUCKET_NAME}" \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }' \
    --region "${REGION}"
echo "✓ Encryption enabled"

# Block public access
echo "Blocking public access..."
aws s3api put-public-access-block \
    --bucket "${BUCKET_NAME}" \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
    --region "${REGION}"
echo "✓ Public access blocked"

# Create DynamoDB table
echo "Creating DynamoDB table..."
if aws dynamodb describe-table --table-name "${DYNAMODB_TABLE}" --region "${REGION}" 2>&1 | grep -q 'ResourceNotFoundException'; then
    aws dynamodb create-table \
        --table-name "${DYNAMODB_TABLE}" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "${REGION}" \
        --tags Key=Name,Value=TerraformStateLock Key=ManagedBy,Value=Terraform > /dev/null
    echo "✓ DynamoDB table created"
    
    # Wait for table to be active
    echo "Waiting for table to be active..."
    aws dynamodb wait table-exists --table-name "${DYNAMODB_TABLE}" --region "${REGION}"
    echo "✓ DynamoDB table is active"
else
    echo "✓ DynamoDB table already exists"
fi

echo ""
echo "Backend setup complete!"
echo ""
echo "Next steps:"
echo "1. Update env/*/backend.conf files with your bucket name: ${BUCKET_NAME}"
echo "2. Run: terraform init -backend-config=env/dev/backend.conf"
echo "3. Run: terraform plan -var-file=env/dev/terraform.tfvars"

