
# TechFlow Cloud Toolkit

[![Terraform Validate](https://github.com/Leanzont/techflow-cloud-toolkit/actions/workflows/terraform-validate.yml/badge.svg)](https://github.com/Leanzont/techflow-cloud-toolkit/actions/workflows/terraform-validate.yml)
[![Docker Build and Push](https://github.com/Leanzont/techflow-cloud-toolkit/actions/workflows/docker.yml/badge.svg)](https://github.com/Leanzont/techflow-cloud-toolkit/actions/workflows/docker.yml)

> A hands-on cloud engineering project that provisions a complete AWS environment using Terraform modules, deploys a containerized Flask API, and includes a custom Python drift detection tool to audit live infrastructure state against declarative configuration.

---

## 🎯 What This Project Solves

**The problem:** How do you know your live AWS resources still match what you declared in code?

**The solution:** A complete cloud toolkit that builds, deploys, and audits its own AWS infrastructure.

---

## 🏗️ Architecture

```
┌──────┐     ┌─────┐      ┌──────┐     ┌───────┐
│   Internet │─→ │ ALB      │─→  │  EC2       │ ─→│   RDS        │
└──────┘     └─────┘      │ (Docker)   │     │ (PostgreSQL) │
                                         └────┬─┘     └───────┘
                                                   │
                                             ┌──┴──┐
                                             │Flask API │
                                             │/health   │
                                             │/data     │
                                             │/drift    │
                                             └─────┘
                                                  │
                                        ┌────┴────┐
                                        │Drift Detector    │
                                        │(Python/Boto3)    │
                                        └─────────┘
```

**Traffic flow:** Internet → ALB (public subnets) → EC2 (public subnets) → RDS (private subnets)

This infrastructure runs inside a single VPC (`10.0.0.0/16`) divided into four subnets — two public and two private across two Availability Zones.

**Public subnets** host the ALB and the EC2 instance. The ALB accepts inbound HTTP traffic from the internet and forwards it to the EC2. The EC2 security group allows inbound SSH (port 22, restricted to a single IP) and accepts HTTP only from the ALB security group — not from the open internet. For outbound traffic, the EC2 connects directly through the Internet Gateway on port 443 (HTTPS) for Docker and AWS services, and port 53 (UDP) for DNS.

**Private subnets** host the RDS PostgreSQL instance. RDS has no public IP and no direct route to the internet — it is only reachable from the EC2 security group on port 5432. However, private resources sometimes need outbound internet access for OS patches or AWS service calls. This is handled by the NAT Gateway, which lives in `public_subnet_1` and holds an Elastic IP. Private subnets route all outbound traffic through it — they can initiate connections to the internet, but the internet cannot initiate connections back to them.

```
Internet → IGW → ALB → EC2                          (inbound public traffic)
EC2 → IGW → Internet                                (EC2 outbound: HTTPS + DNS)
Private Subnet 1 (10.0.10.0/24) ─┐
                                   ├→ NAT Gateway → IGW → Internet
Private Subnet 2 (10.0.11.0/24) ─┘                 (private outbound only)
```

![Architecture Diagram](infrastructure/architecture_diagram_AWS.png)

---

## 📁 Project Structure

```
techflow-cloud-toolkit/
├── .github/workflows/          # CI/CD pipelines
│   ├── terraform-validate.yml  # Terraform fmt, validate, plan on PR
│   └── docker.yml              # Docker build & push (coming soon)
├── infrastructure/             # Terraform modules
│   ├── modules/
│   │   ├── vpc/                # VPC, subnets, route tables
│   │   ├── alb/                # Application Load Balancer
│   │   ├── ec2/                # Compute instances
│   │   ├── rds/                # PostgreSQL database
│   │   ├── s3/                 # Buckets for logs & backups
│   │   └── iam/                # Roles, policies, profiles
│   ├── main.tf                 # Root module composition
│   ├── backend.tf              # S3 remote state
│   ├── variables.tf
│   ├── outputs.tf
│   └── architecture.png        # Network diagram
├── api/                        # Containerized Flask API
│   ├── app.py                  # Flask app (3 endpoints)
│   ├── Dockerfile              # Multi-stage build
│   ├── requirements.txt
│   └── README.md
└── tools/
    └── drift_detector/         # Infrastructure drift detection
        ├── drift_detector.py   # Main script (EC2, RDS, S3)
        ├── expected.yaml       # Desired state config
        └── README.md
```

---

## ✅ Current Status

| Component                                            | Status     | Notes                                                                                                                                 |
| ---------------------------------------------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| AWS Infrastructure (VPC, ALB, EC2, RDS, S3, IAM)     | ✅ Complete | Modular Terraform, 2 AZs, private data tier                                                                                           |
| Containerized Flask API                              | ✅ Complete | 3 endpoints: /health, /data, /drift                                                                                                   |
| Drift Detector                                       | ✅ Complete | Detects missing, changed, and unexpected resources                                                                                    |
| CI/CD GitHub Actions (Terraform)                     | ✅ Complete | fmt → validate → plan on every push                                                                                                   |
| CI/CD GitHub Actions (Docker)                        | ✅ Complete | CI on PR: build without push → CD on merge: build & push to Docker Hub                                                                |
| Architecture Diagram                                 | ✅ Complete | Draw.io diagram with CIDRs and traffic flow                                                                                           |
| IMDSv2 Enforcement                                   | ✅ Complete | Blocks SSRF-based credential theft via EC2 metadata service                                                                           |
| NAT Gateway (private subnet outbound)                | ✅ Complete | EIP + NAT GW in public_subnet_1, private route table for both private subnets                                                         |
| S3 Bucket Policy (TLS enforcement)                   | ✅ Complete | `aws:SecureTransport = false` + `Deny` + `Principal: *` blocks all HTTP access to both buckets                                        |
| IAM Policy hardening (TLS + SID + Delete protection) | ✅ Complete | `aws:SecureTransport` condition on all S3 actions, SID identifiers on every statement, explicit Deny on DeleteObject and DeleteBucket |
| ALB as EC2 front door (Security Group referencing)   | ✅ Complete | EC2 accepts HTTP only from ALB SG — not from internet. Health check on `/health`. Egress restricted to 443 + 53                       |


---

## 🛠 Stack

- **Terraform** — Infrastructure as Code
- - **AWS** — VPC, EC2, RDS, S3, ALB, IAM, NAT Gateway
- **Python / Boto3** — AWS SDK, drift detection logic
- **Docker** — Containerization
- **Flask** — REST API
- **GitHub Actions** — CI/CD

---

## 🚀 Quick Start

### Prerequisites

- Terraform >= 1.10
- AWS CLI configured
- Docker (optional, for API)
- Python 3.10+ (optional, for drift detector)

### 1. Infrastructure

```bash
cd infrastructure/
terraform init
terraform plan
terraform apply
```

### 2. API (Local)

```bash
cd api/
docker build -f Dockerfile -t techflow-api ..
docker run -p 5000:5000 techflow-api
```

### 3. Drift Detector

```bash
cd tools/drift_detector/
pip install -r requirements.txt
python drift_detector.py --config expected.yaml
```

---

## 🧠 What I Learned

1. **Modular Terraform design** — Each AWS service is an independent module with its own variables, outputs, and resources.
2. **Two-pass drift detection** — Extract AWS state into dictionaries, then compare against expected config using lookups (not nested loops).
3. **CI/CD guardrails** — `terraform fmt -check` caught formatting issues before they reached the repo.
4. **Remote state with S3** — Using `use_lockfile` for native state locking without DynamoDB.
5. **Unexpected resource detection** — Set operations (`aws_names - expected_names`) find resources that exist in AWS but aren't in config.
6. **API as a bridge** — A Flask API alone is just an endpoint. Real value comes when it connects to something meaningful. I integrated the drift detector into a `/drift` endpoint so the API serves as the public interface for infrastructure audits. Containerizing it with Docker means the runtime, dependencies, and code ship together — no "works on my machine" problems.
7. **IMDSv2 as defense-in-depth** — Enforcing `http_tokens = "required"` on EC2 instances blocks the #1 attack vector for IAM credential theft (SSRF). Verified: IMDSv1 returns 401 Unauthorized, IMDSv2 with session token works. `http_put_response_hop_limit = 1` prevents Docker containers from reaching the metadata service.
8. **Traffic Control — ALB + EC2 Security Groups** — I learned how to 
control HTTP traffic to EC2 instances using an ALB as the front door. 
The traffic flow is:
`Internet → port 80 → ALB → EC2`
For outbound traffic, the EC2 connects directly through:
`EC2 → port 443 (HTTPS) + port 53 (DNS) → Internet Gateway → Internet`
This is more secure because nobody can reach the EC2 directly on port 80. 
Before this change, the EC2 accepted HTTP from 0.0.0.0/0, which is a 
security risk. The solution uses Security Group referencing across three 
files: modules/alb/main.tf, modules/ec2/main.tf, and root/main.tf as 
the orchestrator.
9. **NAT Gateway for private subnet outbound access** — Private subnets have no route to the Internet Gateway by design, which is correct for security. But that also means resources inside them — like RDS — cannot initiate outbound connections for updates or AWS service calls. The NAT Gateway solves this asymmetry: it allows private resources to reach the internet, while the internet cannot reach them back. It lives in a public subnet because it needs a route to the Internet Gateway to forward traffic outward. It holds an Elastic IP so the source address is always stable and predictable. Private subnets get a dedicated route table with a single rule: `0.0.0.0/0 → NAT Gateway`. The pattern is identical to how public subnets work — the only difference is the route target: public subnets point to the IGW, private subnets point to the NAT Gateway.
10. **TLS enforcement with `aws:SecureTransport`** — Both the S3 bucket policy and the IAM role policy include a condition that enforces encrypted traffic. The logic works as a conditional block: if a request arrives over HTTP (`aws:SecureTransport = false`), the effect is `Deny` — access is blocked regardless of who is making the request. If the request arrives over HTTPS (`aws:SecureTransport = true`), the deny condition does not trigger and the allow rules apply normally. This creates a hard enforcement layer: even if credentials are valid, unencrypted requests never reach the bucket. The S3 bucket policy uses `Principal: *` with `Deny`, which means it applies to everyone — including the root account — making it impossible to accidentally access the bucket over HTTP. The IAM policy applies the same condition to `s3:ListBucket`, `s3:GetObject`, and `s3:PutObject`, so the EC2 role itself is also bound to HTTPS-only access.

11. **SID identifiers in IAM policies** — Every policy statement includes a `Sid` (Statement ID) field with a descriptive name: `AllowListBuckets`, `DenyS3DeleteOperations`, `AllowEC2ToAssumeRole`. SIDs are optional in AWS, but they serve two practical purposes: they make each statement self-documenting so anyone reading the policy immediately understands its intent, and they make CloudWatch and CloudTrail logs easier to search — when a permission is evaluated or denied, the SID appears in the log entry, so you can find exactly which statement triggered it without reverse-engineering the JSON.


---

## 🔮 Future Improvements

- [x] CI/CD Docker workflow (build + push to Docker Hub)
- [x] IMDSv2 enforcement on EC2 instances
- [x] IAM Hardening: least privilege policies, TLS conditions, bucket policies
- [ ] Connect Flask API to RDS PostgreSQL for persistent storage
- [x] Add NAT Gateway for private subnet outbound access
- [ ] CloudWatch alarms for EC2 and RDS
- [ ] Replace SSH key pairs with AWS Systems Manager (SSM) Session Manager
- [ ] Add WAF rules to the ALB
- [ ] AWS Certified Solutions Architect — Associate (Dec 2026)

---

## 📬 Connect

- [LinkedIn](https://www.linkedin.com/in/leandro-fabian-zenteno-soliz-3ba1713b7/)
- Built by **Leandro Zenteno** — Junior Cloud/DevOps Engineer

---

## 📄 License

MIT





