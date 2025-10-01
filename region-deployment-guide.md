# Multi-Region Deployment Guide

## Template Flexibility
This CloudFormation template is designed to work across all AWS regions with minimal modifications.

## Region-Specific Requirements

### 1. AMI ID (Required for each region)
You need to copy your golden AMI to each target region:

#### For Ohio (us-east-2):
```bash
# AMI already exists: ami-0ce40bd4273a45d61
```

#### For other regions:
```bash
# Copy AMI from us-east-2 to target region
aws ec2 copy-image \
  --source-image-id ami-0ce40bd4273a45d61 \
  --source-region us-east-2 \
  --region <target-region> \
  --name "sagesoft-hris-production-ec2-GOLDEN-IMAGE-v2"
```

### 2. ACM Certificate (Required for each region)
SSL certificates are region-specific. You need to:

1. **Request certificate in target region:**
```bash
aws acm request-certificate \
  --domain-name "*.ssi-test.link" \
  --validation-method DNS \
  --region <target-region>
```

2. **Or import existing certificate:**
```bash
aws acm import-certificate \
  --certificate fileb://certificate.pem \
  --private-key fileb://private-key.pem \
  --certificate-chain fileb://certificate-chain.pem \
  --region <target-region>
```

### 3. RDS Snapshot (Required for each region)
Copy your RDS snapshot to target region:

```bash
aws rds copy-db-snapshot \
  --source-db-snapshot-identifier sagesoft-hris-production-rds-golden-image \
  --target-db-snapshot-identifier sagesoft-hris-production-rds-golden-image \
  --source-region us-east-2 \
  --target-region <target-region>
```

### 4. Key Pair (Required for each region)
Import your key pair to target region:

```bash
aws ec2 import-key-pair \
  --key-name sagesoft-hris-production-ec2-pk \
  --public-key-material fileb://sagesoft-hris-production-ec2-pk.pub \
  --region <target-region>
```

## Deployment Commands by Region

### Ohio (us-east-2)
```bash
aws cloudformation create-stack \
  --stack-name sagesoft-hris-production \
  --template-body file://sagesoft-hris-production-infrastructure.yaml \
  --parameters ParameterKey=AMIId,ParameterValue=ami-0ce40bd4273a45d61 \
               ParameterKey=ACMCertificateArn,ParameterValue=arn:aws:acm:us-east-2:ACCOUNT:certificate/CERT-ID \
  --region us-east-2 \
  --capabilities CAPABILITY_IAM
```

### Virginia (us-east-1)
```bash
aws cloudformation create-stack \
  --stack-name sagesoft-hris-production \
  --template-body file://sagesoft-hris-production-infrastructure.yaml \
  --parameters ParameterKey=AMIId,ParameterValue=ami-XXXXXXXXX \
               ParameterKey=ACMCertificateArn,ParameterValue=arn:aws:acm:us-east-1:ACCOUNT:certificate/CERT-ID \
  --region us-east-1 \
  --capabilities CAPABILITY_IAM
```

### Oregon (us-west-2)
```bash
aws cloudformation create-stack \
  --stack-name sagesoft-hris-production \
  --template-body file://sagesoft-hris-production-infrastructure.yaml \
  --parameters ParameterKey=AMIId,ParameterValue=ami-XXXXXXXXX \
               ParameterKey=ACMCertificateArn,ParameterValue=arn:aws:acm:us-west-2:ACCOUNT:certificate/CERT-ID \
  --region us-west-2 \
  --capabilities CAPABILITY_IAM
```

## WAF Compatibility
The template now uses only the most universally available WAF managed rule groups:
- **Core Rule Set**: Available in all regions
- **Amazon IP Reputation List**: Available in all regions

## Region-Agnostic Features
These components work automatically across all regions:
- ✅ VPC and networking
- ✅ Security Groups
- ✅ EFS
- ✅ Load Balancer
- ✅ WAF (simplified rule set)
- ✅ All tagging and outputs

## Pre-Deployment Checklist

### For Ohio (us-east-2) - Ready ✅
- [x] AMI: ami-0ce40bd4273a45d61
- [x] RDS Snapshot: sagesoft-hris-production-rds-golden-image
- [x] Key Pair: sagesoft-hris-production-ec2-pk
- [ ] ACM Certificate: Get ARN for *.ssi-test.link

### For Other Regions - Preparation Needed
- [ ] Copy AMI to target region
- [ ] Copy RDS snapshot to target region
- [ ] Import key pair to target region
- [ ] Request/import ACM certificate in target region

## Deployment Script Template
```bash
#!/bin/bash
REGION="us-east-2"  # Change this
AMI_ID="ami-0ce40bd4273a45d61"  # Change this
CERT_ARN="arn:aws:acm:${REGION}:ACCOUNT:certificate/CERT-ID"  # Change this

aws cloudformation create-stack \
  --stack-name sagesoft-hris-production \
  --template-body file://sagesoft-hris-production-infrastructure.yaml \
  --parameters ParameterKey=AMIId,ParameterValue=${AMI_ID} \
               ParameterKey=ACMCertificateArn,ParameterValue=${CERT_ARN} \
  --region ${REGION} \
  --capabilities CAPABILITY_IAM
```

This template is now fully region-flexible and can be deployed anywhere with the appropriate regional resources!
