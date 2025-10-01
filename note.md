Pre-requisites:
1. Copy the EC2 AMI
2.  Copy the RDS Snapshot
#Copy AMI from Region1 to Region2
aws ec2 copy-image \
  --source-image-id ami-06919e9fdbcf4b935 \
  --source-region us-east-1 \
  --region us-east-2 \
  --name "sagesoft-hris-production-ec2-GOLDEN-IMAGE-v2"
\
3. Create ACM for Load Balancer


AI PROMPT:
- act as a DevOps Engineer, that create a Cloudformation Templates using these:
    - VPC SECTION
        - Subnet Address: 10.0.0.0/26
        - Availability Zone: 2
        - Number of public subnet: 2
        - Number of Privite subnet: 2
        - Nat Gateway: NONE
        - VPC endpoint: S3 Gateway
        - NACL Name: sagesoft-hris-production-acl
            * Associated VPC: sagesoft-hris-production-vpc
            * Tags:
                * Organization: Sagesoft
                * Name: sagesoft-hris-production-acl
                * Environment: Demo
                * Country Name: PH
                * Province Name: Metro Manila
                * Locality Name: San Juan City
                * Author: SSI Tech
            Inbound Rules
            1. HTTPS (443) → TCP, Port 443, Source 0.0.0.0/0, Allow
            2. HTTP (80) → TCP, Port 80, Source 0.0.0.0/0, Allow
            3. Custom TCP → TCP, Port Range 1025–65535, Source 0.0.0.0/0, Allow
            4. All Traffic → ALL protocols, Source 10.0.0.0/26, Allow
            Outbound Rules
            1. HTTPS (443) → TCP, Port 443, Destination 0.0.0.0/0, Allow
            2. HTTP (80) → TCP, Port 80, Destination 0.0.0.0/0, Allow
            3. Custom TCP → TCP, Port Range 1025–65535, Destination 0.0.0.0/0, Allow
            4. All Traffic → ALL protocols, Destination 10.0.0.0/26, Allow
    - SECURITY GROUP SECTION
        * Use a parameter named VpcId so the VPC ID can be passed dynamically.
        * Each Security Group must include tags:
            * Organization: Sagesoft
            * Name: <SG name>
            * Environment: Demo
            * Country Name: PH
            * Province Name: Metro Manila
            * Locality Name: San Juan City
            * Author: SSI Tech
        * Output each Security Group ID.

        Security Groups
        1. Web Server Security Group
        * Name: sagesoft-hris-production-ec2-sg
        * Description: sagesoft-hris-production-ec2-sg
        * Inbound Rules:
            * HTTP (TCP/80) → Source: 10.0.0.0/26 (VPC CIDR Range)
            * SSH (TCP/22) → Source: 10.0.0.0/26 (VPC CIDR Range)
        * Outbound Rules:
            * MySQL/Aurora (TCP/3306) → Destination: 10.0.0.0/26
            * HTTP (TCP/80) → Destination: 10.0.0.0/26
            * HTTPS (TCP/443) → Destination: 10.0.0.0/26
            * NFS (TCP/2049) → Destination: 10.0.0.0/26
            * HTTP (ALL ports) → Destination: 10.0.0.0/26

        2. Load Balancer Security Group
        * Name: sagesoft-hris-production-lb-sg
        * Description: sagesoft-hris-production-lb-sg
        * Inbound Rules:
            * HTTPS (TCP/443) → Source: 0.0.0.0/0 (Public Access)
            * HTTP (TCP/80) → Source: 0.0.0.0/0 (Public Access)
        * Outbound Rules:
            * HTTPS (TCP/443) → Destination: 10.0.0.0/26
            * HTTP (TCP/80) → Destination: 10.0.0.0/26

        3. Auto Scaling Group Security Group
        * Name: sagesoft-hris-production-asg-sg
        * Description: sagesoft-hris-production-asg-sg
        * Inbound Rules:
            * HTTPS (TCP/443) → Source: 0.0.0.0/0 (Public Access)
            * HTTP (TCP/80) → Source: 0.0.0.0/0 (Public Access)
            * MySQL/Aurora (TCP/3306) → Source: 10.0.0.0/26
            * NFS (TCP/2049) → Source: 10.0.0.0/26
        * Outbound Rules:
            * HTTPS (TCP/443) → Destination: 0.0.0.0/0
            * HTTP (TCP/80) → Destination: 0.0.0.0/0
            * MySQL/Aurora (TCP/3306) → Destination: 10.0.0.0/26
            * NFS (TCP/2049) → Destination: 10.0.0.0/26

        4. Elastic File System Security Group
        * Name: sagesoft-hris-production-efs-sg
        * Description: sagesoft-hris-production-efs-sg
        * Inbound Rules:
            * All traffic (ALL protocols/ports) → Source: 10.0.0.0/26
        * Outbound Rules:
            * All traffic (ALL protocols/ports) → Destination: 0.0.0.0/0

        5. Database Security Group
        * Name: sagesoft-hris-production-rds-sg
        * Description: sagesoft-hris-production-rds-sg
        * Inbound Rules:
            * MySQL/Aurora (TCP/3306) → Source: 10.0.0.0/26
    - EC2 SECTION
        - Launch using this EC2 AMI "sagesoft-hris-production-ec2-GOLDEN-IMAGE-v2"
        - PEM KEY "sagesoft-hris-production-ec2-pk.pem" already Imported
        - use the created VPC "sagesoft-hris-production-vpc"
        - use the Public Subnet created in VPC
        - use the Created SG "sagesoft-hris-production-ec2-sg"
    - Launch using this RDS Snapshot "sagesoft-hris-production-rds-golden-image"
        - use the created VPC "sagesoft-hris-production-vpc"
        - use the Private Subnet created in VPC
        - use the Created SG "sagesoft-hris-production-rds-sg"
    - EFS "sagesoft-hris-production-efs"
        - use the created SG "sagesoft-hris-production-efs-sg"
    - LOAD BALANCER SECTION
    Create an Application Load Balancer stack that includes:
* A Target Group named ssi-roadshow-demo-tg (instance type targets, protocol HTTPS on port 443, in ssi-roadshow-demo-vpc, health checks on / using HTTPS).
* An ALB named ssi-roadshow-demo-lb (internet-facing, IPv4, using ssi-roadshow-demo-lb-sg, attached to two public subnets).
* A Listener on port 443 using HTTPS with an ACM certificate (*.ssi-test.link "57ebe126-9b78-439b-930c-56b1d068774d") that forwards traffic to the target group.
* Tags: Organization=Sagesoft Solutions Inc., Name=ssi-roadshow-demo-lb, Environment=Production, Country=PH, Province=Metro Manila, Locality=San Juan City, Author=SSI Tech.
* A WAF association to an existing Web ACL (ssi-roadshow-demo-waf).
Make ACM certificate ARN and Web ACL ARN parameters.
