# AWS Console CloudFormation Deployment Guide

## Step-by-Step Guide to Deploy Sagesoft HRIS Infrastructure via AWS Console

### Prerequisites Checklist
Before starting, ensure you have:
- [ ] AWS Console access with CloudFormation permissions
- [ ] AMI `ami-0ce40bd4273a45d61` available in Ohio
- [ ] RDS Snapshot `sagesoft-hris-production-rds-golden-image` in Ohio
- [ ] Key Pair `sagesoft-hris-production-ec2-pk` in Ohio
- [ ] ACM Certificate `arn:aws:acm:us-east-2:870795464271:certificate/57ebe126-9b78-439b-930c-56b1d068774d`

---

## Part 1: Verify Prerequisites

### Check AMI Availability
1. **Navigate to EC2 Console**
   - Go to AWS Console → Services → EC2
   - Ensure you're in **Ohio (us-east-2)** region
   - Go to Images → AMIs
   - Search for: `ami-0ce40bd4273a45d61`
   - Status should be **Available**

### Check RDS Snapshot
1. **Navigate to RDS Console**
   - Go to AWS Console → Services → RDS
   - Ensure you're in **Ohio (us-east-2)** region
   - Go to Snapshots
   - Find: `sagesoft-hris-production-rds-golden-image`
   - Status should be **Available**

### Check Key Pair
1. **Navigate to EC2 Console**
   - Go to Network & Security → Key Pairs
   - Find: `sagesoft-hris-production-ec2-pk`
   - Should be listed and available

### Check ACM Certificate
1. **Navigate to Certificate Manager**
   - Go to AWS Console → Services → Certificate Manager
   - Ensure you're in **Ohio (us-east-2)** region
   - Find certificate with ID: `57ebe126-9b78-439b-930c-56b1d068774d`
   - Status should be **Issued**
   - Domain should be `*.ssi-test.link`

---

## Part 2: Deploy CloudFormation Stack

### Step 1: Access CloudFormation
1. **Navigate to CloudFormation**
   - AWS Console → Services → CloudFormation
   - Ensure you're in **Ohio (us-east-2)** region

### Step 2: Create Stack
1. **Start Stack Creation**
   - Click **Create stack** → **With new resources (standard)**

### Step 3: Specify Template
1. **Choose Template Source**
   - Select **Upload a template file**
   - Click **Choose file**
   - Upload `sagesoft-hris-production-infrastructure.yaml`
   - Click **Next**

### Step 4: Stack Details
1. **Stack Name**
   - Enter: `sagesoft-hris-production`

2. **Parameters (All Pre-Configured)**
   - **AMIId**: `ami-0ce40bd4273a45d61` (pre-filled)
   - **ACMCertificateArn**: `arn:aws:acm:us-east-2:870795464271:certificate/57ebe126-9b78-439b-930c-56b1d068774d` (pre-filled)
   
   **Note**: No parameter changes needed - all defaults are correct!

3. **Click Next**

### Step 5: Configure Stack Options
1. **Tags (Optional but Recommended)**
   - Key: `Project`, Value: `Sagesoft HRIS`
   - Key: `Environment`, Value: `Production`
   - Key: `Owner`, Value: `Your Name`

2. **Permissions**
   - Leave **IAM role** blank (uses your permissions)

3. **Stack failure options**
   - Select **Roll back all stack resources**

4. **Advanced options**
   - Leave defaults

5. **Click Next**

### Step 6: Review and Create
1. **Review Configuration**
   - Verify stack name: `sagesoft-hris-production`
   - Verify parameters are correct
   - Check template shows all expected resources

2. **Capabilities**
   - ✅ Check **I acknowledge that AWS CloudFormation might create IAM resources**

3. **Create Stack**
   - Click **Create stack**

---

## Part 3: Monitor Deployment

### Step 1: Watch Stack Progress
1. **Stack Status**
   - Status should show: `CREATE_IN_PROGRESS`
   - Refresh page to see updates

2. **Events Tab**
   - Monitor resource creation in real-time
   - Look for any `CREATE_FAILED` events

### Step 2: Expected Creation Order
Resources will be created in this approximate order:
1. **VPC and Networking** (2-3 minutes)
   - VPC, Subnets, Internet Gateway, Route Tables
2. **Security Groups** (1 minute)
   - All 5 security groups
3. **EFS and RDS** (5-10 minutes)
   - EFS file system and mount targets
   - RDS instance from snapshot
4. **EC2 Instance** (2-3 minutes)
   - EC2 with UserData script execution
   - **Automated Configuration**: EFS mounting, session migration, database setup
5. **Load Balancer** (3-5 minutes)
   - ALB, Target Group, HTTP redirect listener, HTTPS listener
6. **WAF** (1-2 minutes)
   - WAF Web ACL and association

### Step 3: Total Deployment Time
- **Expected Duration**: 15-25 minutes
- **Status**: `CREATE_COMPLETE` when finished

---

## Part 4: Verify Deployment (Automated Features)

### Step 1: Check Stack Outputs
1. **Navigate to Outputs Tab**
   - Click on your stack name
   - Go to **Outputs** tab
   - Verify all outputs are present:
     - VPC ID
     - Security Group IDs
     - Load Balancer DNS
     - EFS ID
     - RDS Endpoint
     - WAF ARN

### Step 2: Test Load Balancer (Production Configuration)
1. **Get Load Balancer DNS**
   - Copy **LoadBalancerDNS** from outputs
   - Example: `ssi-roadshow-demo-lb-123456789.us-east-2.elb.amazonaws.com`

2. **Test HTTP Redirect**
   - Browse to: `http://[LoadBalancerDNS]`
   - Should automatically redirect to HTTPS with 301 status

3. **Test HTTPS Application**
   - Browse to: `https://[LoadBalancerDNS]`
   - Should show your application with valid SSL certificate
   - Check browser shows secure connection (lock icon)

### Step 3: Verify Automated Configuration
1. **EC2 Instance Status**
   - Go to EC2 Console
   - Find instance: `sagesoft-hris-production-ec2`
   - Status should be **Running**

2. **RDS Database**
   - Go to RDS Console
   - Find database: `sagesoft-hris-production-rds`
   - Status should be **Available**

3. **EFS Mount (Automated)**
   - EFS should be automatically mounted at `/mnt/efs-sessions`
   - Laravel sessions automatically migrated to `/mnt/efs-sessions/laravel-sessions`
   - Proper apache ownership set automatically

4. **Database Connection (Automated)**
   - `.env` file automatically updated with RDS endpoint
   - Web server automatically restarted
   - Application should connect to database without manual configuration

---

## Part 5: Application Verification

### Step 1: Test Application Functionality
1. **Access Application**
   - Use Load Balancer DNS: `https://[LoadBalancerDNS]`
   - Application should load completely
   - Database connectivity should work
   - Session management should function

2. **Verify SSL Certificate**
   - Browser should show secure connection
   - Certificate should be valid for `*.ssi-test.link`
   - No SSL warnings or errors

### Step 2: Health Check Verification
1. **Target Group Health**
   - Go to EC2 → Load Balancers → Target Groups
   - Find: `ssi-roadshow-demo-tg`
   - Target should show **Healthy** status
   - Health check should pass with 200 or 302 response

---

## Part 6: Troubleshooting (Rare Issues)

### Issue 1: Stack Creation Fails
**Most Common Causes**:
- AMI not available in Ohio region
- RDS snapshot not available in Ohio region
- Key pair doesn't exist in Ohio region
- ACM certificate not issued or wrong ARN

**Solution**: Verify all prerequisites exist in Ohio region

### Issue 2: Application Not Accessible
**Check These**:
1. **Security Groups**: Ensure ALB security group allows HTTP/HTTPS from internet
2. **Target Group Health**: Check if EC2 instance is healthy in target group
3. **EC2 Instance**: Verify instance is running and web server is active

### Issue 3: SSL Certificate Issues
**Verify**:
- Certificate status is **Issued** in ACM
- Certificate covers `*.ssi-test.link` domain
- Certificate is in Ohio (us-east-2) region

---

## Part 7: Post-Deployment (Optional)

### Step 1: Custom Domain Setup
1. **Update DNS Records**
   - Point your domain to Load Balancer DNS
   - Create CNAME: `app.ssi-test.link` → `[LoadBalancerDNS]`

2. **Test Custom Domain**
   - Browse to: `https://app.ssi-test.link`
   - Should work with valid SSL certificate

### Step 2: Monitoring Setup
1. **CloudWatch Metrics**
   - ALB metrics for request count and latency
   - EC2 metrics for CPU and memory usage
   - RDS metrics for database performance

2. **WAF Monitoring**
   - Go to WAF Console
   - Check `ssi-roadshow-demo-waf`
   - Monitor allowed/blocked requests

---

## Success Indicators

✅ **Deployment Successful When**:
- Stack status: `CREATE_COMPLETE`
- All outputs populated
- HTTP redirects to HTTPS automatically
- HTTPS serves application with valid SSL
- Target group shows healthy targets
- Application functions completely
- Database connectivity works
- Session management operational

## Automated Features Working

✅ **These Work Automatically (No Manual Setup)**:
- EFS mounting with proper fstab entry
- Laravel session migration and configuration
- Database endpoint configuration in application
- Web server restart and configuration application
- HTTP to HTTPS redirect
- SSL certificate installation
- Target group health checks with 200/302 codes

🎉 **Your Sagesoft HRIS infrastructure is now fully operational!**

**Total Setup Time**: 15-25 minutes with zero manual configuration required!
