#!/bin/bash

# CloudFormation Stack Deployment Script
set -e

# Configuration
STACK_NAME="infrastructure-master"
REGION="us-east-1"
ENVIRONMENT="dev"

# Required parameters - update these values
AMI_ID="ami-0abcdef1234567890"  # Update with your AMI ID
DB_SNAPSHOT_ID="your-snapshot-id"  # Update with your RDS snapshot ID
DOMAIN_NAME="example.com"  # Update with your domain

# Upload templates to S3 bucket (create bucket if needed)
BUCKET_NAME="${STACK_NAME}-templates-$(date +%s)"
aws s3 mb s3://${BUCKET_NAME} --region ${REGION}

# Upload nested templates
aws s3 cp networking.yaml s3://${BUCKET_NAME}/
aws s3 cp compute.yaml s3://${BUCKET_NAME}/
aws s3 cp database.yaml s3://${BUCKET_NAME}/
aws s3 cp storage.yaml s3://${BUCKET_NAME}/
aws s3 cp lb-waf.yaml s3://${BUCKET_NAME}/
aws s3 cp dns.yaml s3://${BUCKET_NAME}/

# Update master template with S3 URLs
sed -i.bak "s|./networking.yaml|https://${BUCKET_NAME}.s3.amazonaws.com/networking.yaml|g" master.yaml
sed -i.bak "s|./compute.yaml|https://${BUCKET_NAME}.s3.amazonaws.com/compute.yaml|g" master.yaml
sed -i.bak "s|./database.yaml|https://${BUCKET_NAME}.s3.amazonaws.com/database.yaml|g" master.yaml
sed -i.bak "s|./storage.yaml|https://${BUCKET_NAME}.s3.amazonaws.com/storage.yaml|g" master.yaml
sed -i.bak "s|./lb-waf.yaml|https://${BUCKET_NAME}.s3.amazonaws.com/lb-waf.yaml|g" master.yaml
sed -i.bak "s|./dns.yaml|https://${BUCKET_NAME}.s3.amazonaws.com/dns.yaml|g" master.yaml

# Deploy the stack
echo "Deploying CloudFormation stack..."
aws cloudformation create-stack \
  --stack-name ${STACK_NAME} \
  --template-body file://master.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=${ENVIRONMENT} \
    ParameterKey=AMIId,ParameterValue=${AMI_ID} \
    ParameterKey=DBSnapshotId,ParameterValue=${DB_SNAPSHOT_ID} \
    ParameterKey=DomainName,ParameterValue=${DOMAIN_NAME} \
  --capabilities CAPABILITY_IAM \
  --region ${REGION}

echo "Stack deployment initiated. Monitor progress in AWS Console."
echo "Bucket created: ${BUCKET_NAME}"

# Restore original master template
mv master.yaml.bak master.yaml
