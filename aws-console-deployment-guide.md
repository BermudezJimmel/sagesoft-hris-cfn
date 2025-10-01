# AWS Console CloudFormation Deployment Guide

## Step-by-Step Guide to Deploy Sagesoft HRIS Infrastructure via AWS Console

### Prerequisites Checklist
Before starting, ensure you have:
- [ ] AWS Console access with CloudFormation permissions
- [ ] ACM Certificate for `*.ssi-test.link` in Ohio region
- [ ] AMI `ami-0ce40bd4273a45d61` available in Ohio
- [ ] RDS Snapshot `sagesoft-hris-production-rds-golden-image` in Ohio
- [ ] Key Pair `sagesoft-hris-production-ec2-pk` in Ohio

---

## Part 1: Get Your ACM Certificate ARN

### Option A: If Certificate Already Exists
1. **Navigate to Certificate Manager**
   - Go to AWS Console → Services → Certificate Manager
   - Ensure you're in **Ohio (us-east-2)** region
   - Find your `*.ssi-test.link` certificate
   - Copy the **Certificate ARN** (starts with `arn:aws:acm:us-east-2:...`)

### Option B: If Certificate Doesn't Exist
1. **Request New Certificate**
   - Go to Certificate Manager → Request a certificate
   - Choose **Request a public certificate**
   - Domain name: `*.ssi-test.link`
   - Validation method: **DNS validation** (recommended)
   - Click **Request**
   - Follow DNS validation steps
   - Wait for certificate to be **Issued** status
   - Copy the **Certificate ARN**

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

2. **Parameters**
   - **AMIId**: `ami-0ce40bd4273a45d61` (pre-filled)
   - **ACMCertificateArn**: Paste your certificate ARN from Part 1
   
   Example:
   ```
   arn:aws:acm:us-east-2:123456789012:certificate/12345678-1234-1234-1234-123456789012
   ```

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
5. **Load Balancer** (3-5 minutes)
   - ALB, Target Group, Listener
6. **WAF** (1-2 minutes)
   - WAF Web ACL and association

### Step 3: Total Deployment Time
- **Expected Duration**: 15-25 minutes
- **Status**: `CREATE_COMPLETE` when finished

---

## Part 4: Verify Deployment

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

### Step 2: Test Components
1. **Load Balancer**
   - Copy **LoadBalancerDNS** from outputs
   - Test in browser: `https://[LoadBalancerDNS]`
   - Should show your application or health check page

2. **EC2 Instance**
   - Go to EC2 Console
   - Find instance: `sagesoft-hris-production-ec2`
   - Status should be **Running**

3. **RDS Database**
   - Go to RDS Console
   - Find database: `sagesoft-hris-production-rds`
   - Status should be **Available**

---

## Part 5: Troubleshooting Common Issues

### Issue 1: Certificate Not Found
**Error**: `Certificate 'arn:aws:acm:...' not found`
**Solution**: 
- Verify certificate exists in Ohio region
- Check certificate ARN is correct
- Ensure certificate status is **Issued**

### Issue 2: AMI Not Found
**Error**: `Invalid id: "ami-..." (expecting "ami-...")`
**Solution**:
- Verify AMI exists in Ohio region
- Check AMI ID is correct: `ami-0ce40bd4273a45d61`

### Issue 3: Key Pair Not Found
**Error**: `The key pair '...' does not exist`
**Solution**:
- Go to EC2 → Key Pairs
- Verify `sagesoft-hris-production-ec2-pk` exists in Ohio

### Issue 4: RDS Snapshot Not Found
**Error**: `DBSnapshotIdentifier ... does not exist`
**Solution**:
- Go to RDS → Snapshots
- Verify `sagesoft-hris-production-rds-golden-image` exists in Ohio

### Issue 5: Stack Rollback
**If stack creation fails**:
1. Check **Events** tab for specific error
2. Fix the issue (certificate, AMI, etc.)
3. Delete the failed stack
4. Create new stack with corrected parameters

---

## Part 6: Post-Deployment Steps

### Step 1: Update DNS (If Needed)
1. **Get Load Balancer DNS**
   - From CloudFormation Outputs tab
   - Example: `ssi-roadshow-demo-lb-123456789.us-east-2.elb.amazonaws.com`

2. **Update DNS Records**
   - Point your domain to the Load Balancer DNS
   - Create CNAME record: `app.ssi-test.link` → `[LoadBalancerDNS]`

### Step 2: Verify Application
1. **Test Application Access**
   - Browse to your domain: `https://app.ssi-test.link`
   - Verify SSL certificate is working
   - Check application functionality

2. **Verify EFS Mount**
   - SSH to EC2 instance
   - Check: `df -h | grep efs`
   - Verify: `/mnt/efs-sessions` is mounted
   - Check: `/mnt/efs-sessions/laravel-session` exists

### Step 3: Monitor Resources
1. **CloudWatch Metrics**
   - Check ALB metrics
   - Monitor EC2 performance
   - Review RDS metrics

2. **WAF Monitoring**
   - Go to WAF Console
   - Check `ssi-roadshow-demo-waf`
   - Monitor blocked/allowed requests

---

## Quick Reference Commands

### Get Certificate ARN
```bash
aws acm list-certificates --region us-east-2
```

### Verify Resources Exist
```bash
# Check AMI
aws ec2 describe-images --image-ids ami-0ce40bd4273a45d61 --region us-east-2

# Check Key Pair
aws ec2 describe-key-pairs --key-names sagesoft-hris-production-ec2-pk --region us-east-2

# Check RDS Snapshot
aws rds describe-db-snapshots --db-snapshot-identifier sagesoft-hris-production-rds-golden-image --region us-east-2
```

---

## Success Indicators

✅ **Deployment Successful When**:
- Stack status: `CREATE_COMPLETE`
- All outputs populated
- Load Balancer DNS accessible via HTTPS
- EC2 instance running
- RDS database available
- EFS mounted on EC2

🎉 **Your Sagesoft HRIS infrastructure is now live!**
