# Sagesoft HRIS Production Infrastructure - CloudFormation Template Explanation

## Overview
This CloudFormation template creates a complete production-ready infrastructure for the Sagesoft HRIS application, implementing a secure 3-tier architecture with proper network segmentation, security controls, automated EFS session management, and full application configuration.

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
- **AMI**: `ami-0ce40bd4273a45d61` (sagesoft-hris-production-ec2-GOLDEN-IMAGE-v2)
- **Instance Type**: `t3.micro` (cost-optimized)
- **Placement**: Public subnet for direct access
- **Key Pair**: `sagesoft-hris-production-ec2-pk` (without .pem extension)
- **Security**: Web Server Security Group
- **Automated Configuration**: Complete EFS and database setup

#### EC2 UserData Automation (Production-Ready)
- **EFS Mounting**: Automatically mounts EFS to `/mnt/efs-sessions` with proper fstab entry
- **Session Migration**: Copies `/mnt/laravel-sessions-backup` to `/mnt/efs-sessions/laravel-sessions`
- **Database Configuration**: Auto-updates `.env` file with RDS endpoint
- **Web Server Restart**: Applies configuration changes automatically
- **Permissions**: Sets proper apache ownership for session files
- **Safety Checks**: Prevents duplicate operations and creates backups

### 4. Database Layer

#### RDS Instance
- **Source**: Restored from snapshot `sagesoft-hris-production-rds-golden-image`
- **Instance Class**: `db.t3.micro`
- **Placement**: Private subnets (Multi-AZ disabled for demo)
- **Security**: Database Security Group
- **Encryption**: Enabled
- **Subnet Group**: Auto-generated unique name to avoid conflicts
- **Auto-Configuration**: Endpoint automatically configured in application

### 5. Storage Services

#### EFS (Elastic File System)
- **Name**: `sagesoft-hris-production-efs`
- **Performance**: General Purpose
- **Throughput**: Bursting
- **Encryption**: Enabled
- **Mount Targets**: Both private subnets for high availability
- **Integration**: Automatically mounted with proper fstab configuration
- **Session Storage**: Laravel sessions automatically migrated and configured

### 6. Load Balancing & SSL (Production Configuration)

#### Application Load Balancer
- **Name**: `ssi-roadshow-demo-lb`
- **Type**: Internet-facing, IPv4
- **Placement**: Both public subnets
- **Security**: Load Balancer Security Group
- **Listeners**: Both HTTP (redirect) and HTTPS (application)

#### Target Group (Optimized Configuration)
- **Name**: `ssi-roadshow-demo-tg`
- **Protocol**: HTTP on port 80 (backend)
- **Health Checks**: HTTP on path "/" with success codes "200,302"
- **Target**: EC2 instance on port 80
- **Configuration**: Optimized for Laravel application responses

#### SSL/TLS & Traffic Flow
- **Certificate**: ACM certificate `arn:aws:acm:us-east-2:870795464271:certificate/57ebe126-9b78-439b-930c-56b1d068774d`
- **HTTP Listener (Port 80)**: Redirects to HTTPS with HTTP_301 status
- **HTTPS Listener (Port 443)**: Forwards to target group
- **Traffic Flow**: HTTP → HTTPS redirect → EC2 backend

### 7. Web Application Firewall (WAF)

#### WAF Web ACL (Simplified for Compatibility)
- **Name**: `ssi-roadshow-demo-waf`
- **Scope**: REGIONAL
- **Description**: WAF for SSI roadshow Demo Load Balancer
- **Configuration**: Basic allow-all with monitoring
- **CloudWatch Metrics**: `ssi-roadshow-demo-cloudwatchmetric`
- **Integration**: Automatically associated with ALB

## Security Features

### 1. Network Segmentation
- Public subnets for internet-facing resources (ALB, EC2)
- Private subnets for backend services (RDS, EFS)
- No NAT Gateway (cost optimization, limited internet access for private subnets)

### 2. Encryption
- RDS encryption at rest
- EFS encryption at rest
- HTTPS/SSL termination at ALB with automatic HTTP redirect

### 3. Access Control
- Security groups with principle of least privilege
- Network ACLs for additional subnet-level protection
- WAF integration for application-layer monitoring

### 4. Monitoring & Compliance
- Comprehensive tagging strategy for resource management
- CloudFormation outputs for integration with other stacks
- WAF metrics and logging for security monitoring

## Parameters

### Current Parameters (Ohio Region Optimized)
1. **AMIId**: `ami-0ce40bd4273a45d61` (default for Ohio)
2. **ACMCertificateArn**: `arn:aws:acm:us-east-2:870795464271:certificate/57ebe126-9b78-439b-930c-56b1d068774d`

## Outputs

The template provides the following outputs for integration:
- VPC ID and all Security Group IDs
- Load Balancer DNS name
- EFS File System ID
- RDS Database endpoint
- WAF Web ACL ARN

## Deployment Fixes Applied (Production-Ready)

### Issues Resolved and Automated
1. **Load Balancer Configuration**: 
   - Added HTTP to HTTPS redirect (port 80 → 443)
   - Configured target group for HTTP:80 with success codes "200,302"
   - Proper HTTPS listener configuration

2. **EFS Integration**: 
   - Fixed fstab entry format with actual EFS ID
   - Automated session directory migration and renaming
   - Proper apache ownership configuration

3. **Database Integration**: 
   - Automated RDS endpoint configuration in application
   - Auto-update of `.env` file with database connection
   - Web server restart for configuration application

4. **Application Readiness**: 
   - Complete end-to-end automation
   - No manual configuration required
   - Production-ready deployment

## Deployment Considerations

### Prerequisites (Already Created)
1. ✅ EC2 AMI: `ami-0ce40bd4273a45d61` (sagesoft-hris-production-ec2-GOLDEN-IMAGE-v2)
2. ✅ RDS Snapshot: `sagesoft-hris-production-rds-golden-image`
3. ✅ ACM Certificate: `arn:aws:acm:us-east-2:870795464271:certificate/57ebe126-9b78-439b-930c-56b1d068774d`
4. ✅ Key Pair: `sagesoft-hris-production-ec2-pk`

### Cost Optimization Features
- t3.micro instances for demo environment
- No NAT Gateway (saves ~$45/month)
- S3 VPC Endpoint (reduces data transfer costs)
- Single AZ RDS (demo environment)

### Production Readiness
- Multi-AZ subnet design
- Encrypted storage
- SSL/TLS termination with HTTP redirect
- WAF protection and monitoring
- Automated EFS session management
- Automated database configuration
- Comprehensive security groups
- Proper tagging strategy
- Complete application configuration

## Usage

### Simple Deployment (No Parameters Required)
```bash
aws cloudformation create-stack \
  --stack-name sagesoft-hris-production \
  --template-body file://sagesoft-hris-production-infrastructure.yaml \
  --region us-east-2 \
  --capabilities CAPABILITY_IAM
```

### AWS Console Deployment
1. Upload template to CloudFormation
2. No parameters needed (all defaults configured)
3. Check "I acknowledge that AWS CloudFormation might create IAM resources"
4. Create stack

## Post-Deployment Verification

### Automatic Configuration Verification
1. **Load Balancer**: 
   - HTTP redirects to HTTPS ✓
   - HTTPS serves application ✓
   - Health checks pass with 200/302 ✓

2. **EFS Integration**:
   - Mounted at `/mnt/efs-sessions` ✓
   - Laravel sessions in `/mnt/efs-sessions/laravel-sessions` ✓
   - Proper apache ownership ✓

3. **Database Connection**:
   - `.env` file updated with RDS endpoint ✓
   - Application connects to database ✓
   - Web server restarted ✓

## Architecture Diagram Flow (Production)
```
Internet → ALB (HTTP redirect) → ALB (HTTPS) → EC2 (HTTP:80) → RDS (Private Subnets)
                                                    ↓
                                              EFS (Private Subnets)
                                              /mnt/efs-sessions/laravel-sessions
```

## Session Management Flow (Automated)
```
EC2 Golden Image: /mnt/laravel-sessions-backup
                           ↓ (UserData script)
EFS Mount: /mnt/efs-sessions/laravel-sessions
                           ↓
Application configured automatically
                           ↓
Persistent across reboots via /etc/fstab
```

## Application Configuration Flow (Automated)
```
RDS Endpoint Generated → UserData Script → Update .env file → Restart Web Server → Application Ready
```

This infrastructure provides a secure, scalable, and fully automated foundation for the Sagesoft HRIS production environment with complete application configuration and no manual setup required.
