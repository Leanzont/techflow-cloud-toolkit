# Infrastructure

Terraform modules that provision the complete AWS environment for the TechFlow Cloud Toolkit.

## What this deploys

| Resource | Module | Purpose |
|----------|--------|---------|
| VPC | `vpc` | Networking: 2 public + 2 private subnets across 2 AZs |
| ALB | `alb` | Application Load Balancer in public subnets |
| EC2 | `ec2` | Compute instances behind the ALB |
| RDS | `rds` | PostgreSQL instance in private subnets |
| S3 | `s3` | Buckets for logs and backups |
| IAM | `iam` | Roles, policies, and instance profiles |

## Architecture & Modules

- **Modular design**: Each service is an independent module with its own variables, outputs, and resources. This makes the infrastructure scalable and reusable.
- **Private data tier**: RDS lives in private subnets with no public access.
- **Least privilege IAM**: Roles and policies scoped to the minimum required permissions.
- **Dynamic AMI selection**: The EC2 module uses an `aws_ami` data source to always fetch the latest Amazon Linux 2 AMI.
- **IP-based SSH access**: The EC2 security group restricts SSH to the deployer's current IP via an `http` data source.

### Traffic flow

```
Internet → IGW → ALB (public subnets) → EC2 (public subnets) → RDS (private subnets)
```

S3 is accessed via IAM from EC2.

![Architecture Diagram](./architecture.png)

## State Management

Terraform state is stored in S3 with native locking (`use_lockfile`) to prevent concurrent modifications.

```hcl
terraform {
  backend "s3" {
    bucket       = "techflow-terraform-state-leandro2026"
    key          = "techflow/terraform.tfstate"
    region       = "us-east-2"
    use_lockfile = true
  }
}
```

## Prerequisites

- Terraform >= 1.5
- AWS CLI configured with credentials
- S3 bucket for remote state (created manually once)
- SSH key pair for EC2 access

## Setup

### 1. Create the S3 bucket for remote state

```bash
aws s3api create-bucket \
  --bucket techflow-terraform-state-leandro2026 \
  --region us-east-2 \
  --create-bucket-configuration LocationConstraint=us-east-2
```

### 2. Generate SSH key pair

```bash
ssh-keygen -t rsa -b 4096 -f modules/ec2/my-key-techflow
```

### 3. Create your local tfvars file

Copy the example file and fill in your real values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Then edit `terraform.tfvars` with your real values. **Never commit this file.**

### 4. Initialize and deploy

```bash
terraform init
terraform plan
terraform apply
```

### 5. Destroy when done

```bash
terraform destroy
```

## Outputs

| Output | Description |
|--------|-------------|
| `ec2_public_ip` | Public IP of the EC2 instance |
| `log_bucket_name_s3` | Name of the logs S3 bucket |
| `backups_bucket_name_s3` | Name of the backups S3 bucket |
| `rds_endpoint` | Connection endpoint for the PostgreSQL instance |

## Modules

### vpc
Creates the VPC, Internet Gateway, 2 public subnets, 2 private subnets, public route table, NAT Gateway, Elastic IP, and private route table. Both private subnets route outbound traffic through the NAT Gateway.

### alb
Creates the Application Load Balancer, target group, HTTP listener, and ALB security group. Health check runs against `/health`.

### ec2
Creates the EC2 instance, security group, and key pair. The security group accepts SSH from a single IP and HTTP only from the ALB security group. Outbound traffic is restricted to port 443 (HTTPS) and port 53 (DNS). IMDSv2 is enforced (`http_tokens = required`, `hop_limit = 1`).

### rds
Creates the RDS PostgreSQL instance, DB subnet group, and security group. The instance lives in private subnets and is only reachable from the EC2 security group on port 5432.

### s3
Creates two S3 buckets (logs and backups) with public access blocked and a bucket policy that denies all non-TLS traffic (`aws:SecureTransport = false` + `Deny`).

### iam
Creates the IAM role, trust policy, and inline policy for EC2. The policy grants S3 read/write/list access with `aws:SecureTransport` enforcement and an explicit Deny on delete operations. All statements include `Sid` identifiers for CloudTrail visibility.

## Future Improvements

- [ ] Connect Flask API to RDS PostgreSQL for persistent storage
- [ ] CloudWatch alarms for EC2 and RDS
- [ ] Replace SSH key pairs with AWS Systems Manager (SSM) Session Manager
- [ ] Add WAF rules to the ALB
