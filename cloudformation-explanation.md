# Sagesoft HRIS Production Infrastructure - CloudFormation Template Explanation

## Overview
This CloudFormation template creates a complete production-ready infrastructure for the Sagesoft HRIS application, implementing a secure 3-tier architecture with proper network segmentation and security controls.

## Architecture Components

### 1. Network Infrastructure (VPC Section)
- **VPC**: `10.0.0.0/26` CIDR block providing 64 IP addresses
- **Subnets**: 4 subnets across 2 Availability Zones
  - Public Subnet 1: `10.0.0.0/28` (16 IPs)
  - Public Subnet 2: `10.0.0.16/28` (16 IPs)
  - Private Subnet 1: `10.0.0.32/28` (16 IPs)
  - Private Subnet 2: `10.0.0.48/28` (16 IPs)
- **Internet Gateway**: Provides internet access to public subnets
- **Route Tables**: Separate routing for public and private subnets
- **S3 VPC Endpoint**: Gateway endpoint for cost-effective S3 access

### 2. Security Layer

#### Network ACL (Stateless)
- **Purpose**: Subnet-level security control
- **Inbound Rules**:
  - HTTPS (443) from anywhere
  - HTTP (80) from anywhere
  - Ephemeral ports (1025-65535) from anywhere
  - All traffic from VPC CIDR
- **Outbound Rules**: Mirror of inbound rules for return traffic

#### Security Groups (Stateful)
1. **Web Server SG** (`sagesoft-hris-production-ec2-sg`)
   - Inbound: HTTP/SSH from VPC only
   - Outbound: Database, HTTP/HTTPS, NFS to VPC

2. **Load Balancer SG** (`sagesoft-hris-production-lb-sg`)
   - Inbound: HTTP/HTTPS from internet
   - Outbound: HTTP/HTTPS to VPC

3. **Auto Scaling Group SG** (`sagesoft-hris-production-asg-sg`)
   - Inbound: HTTP/HTTPS from internet, Database/NFS from VPC
   - Outbound: HTTP/HTTPS to internet, Database/NFS to VPC

4. **EFS SG** (`sagesoft-hris-production-efs-sg`)
   - Inbound: All traffic from VPC
   - Outbound: All traffic to internet

5. **Database SG** (`sagesoft-hris-production-rds-sg`)
   - Inbound: MySQL (3306) from VPC only
   - Outbound: Default (none specified)

### 3. Compute Resources

#### EC2 Instance
- **AMI**: `sagesoft-hris-production-ec2-GOLDEN-IMAGE-v2` (pre-configured)
- **Instance Type**: `t3.micro` (cost-optimized)
- **Placement**: Public subnet for direct access
- **Key Pair**: `sagesoft-hris-production-ec2-pk.pem`
- **Security**: Web Server Security Group

### 4. Database Layer

#### RDS Instance
- **Source**: Restored from snapshot `sagesoft-hris-production-rds-golden-image`
- **Instance Class**: `db.t3.micro`
- **Placement**: Private subnets (Multi-AZ disabled for demo)
- **Security**: Database Security Group
- **Encryption**: Enabled
- **Subnet Group**: Custom DB subnet group spanning both private subnets

### 5. Storage Services

#### EFS (Elastic File System)
- **Name**: `sagesoft-hris-production-efs`
- **Performance**: General Purpose
- **Throughput**: Bursting
- **Encryption**: Enabled
- **Mount Targets**: Both private subnets for high availability

### 6. Load Balancing & SSL

#### Application Load Balancer
- **Name**: `ssi-roadshow-demo-lb`
- **Type**: Internet-facing, IPv4
- **Placement**: Both public subnets
- **Security**: Load Balancer Security Group

#### Target Group
- **Name**: `ssi-roadshow-demo-tg`
- **Protocol**: HTTPS on port 443
- **Health Checks**: HTTPS on path "/"
- **Target**: EC2 instance

#### SSL/TLS
- **Certificate**: ACM certificate for `*.ssi-test.link`
- **Listener**: HTTPS on port 443
- **Security**: WAF protection enabled

## Security Features

### 1. Network Segmentation
- Public subnets for internet-facing resources (ALB, EC2)
- Private subnets for backend services (RDS, EFS)
- No NAT Gateway (cost optimization, limited internet access for private subnets)

### 2. Encryption
- RDS encryption at rest
- EFS encryption at rest
- HTTPS/SSL termination at ALB

### 3. Access Control
- Security groups with principle of least privilege
- Network ACLs for additional subnet-level protection
- WAF integration for application-layer security

### 4. Monitoring & Compliance
- Comprehensive tagging strategy for resource management
- CloudFormation outputs for integration with other stacks

## Parameters

### Required Parameters
1. **ACMCertificateArn**: ARN of the SSL certificate for `*.ssi-test.link`
2. **WebACLArn**: ARN of the existing WAF Web ACL

## Outputs

The template provides the following outputs for integration:
- VPC ID and all Security Group IDs
- Load Balancer DNS name
- EFS File System ID
- RDS Database endpoint

## Deployment Considerations

### Prerequisites (Already Created)
1. ✅ EC2 AMI: `sagesoft-hris-production-ec2-GOLDEN-IMAGE-v2`
2. ✅ RDS Snapshot: `sagesoft-hris-production-rds-golden-image`
3. ✅ ACM Certificate: `*.ssi-test.link`
4. ✅ WAF Web ACL: `ssi-roadshow-demo-waf`

### Cost Optimization Features
- t3.micro instances for demo environment
- No NAT Gateway (saves ~$45/month)
- S3 VPC Endpoint (reduces data transfer costs)
- Single AZ RDS (demo environment)

### Production Readiness
- Multi-AZ subnet design
- Encrypted storage
- SSL/TLS termination
- WAF protection
- Comprehensive security groups
- Proper tagging strategy

## Usage

Deploy this template using:
```bash
aws cloudformation create-stack \
  --stack-name sagesoft-hris-production \
  --template-body file://sagesoft-hris-production-infrastructure.yaml \
  --parameters ParameterKey=ACMCertificateArn,ParameterValue=arn:aws:acm:region:account:certificate/cert-id \
               ParameterKey=WebACLArn,ParameterValue=arn:aws:wafv2:region:account:regional/webacl/name/id \
  --capabilities CAPABILITY_IAM
```

## Architecture Diagram Flow
```
Internet → ALB (Public Subnets) → EC2 (Public Subnet) → RDS (Private Subnets)
                                     ↓
                                EFS (Private Subnets)
```

This infrastructure provides a secure, scalable, and cost-effective foundation for the Sagesoft HRIS production environment.
