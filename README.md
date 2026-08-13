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

S3 is accessed via IAM from EC2 for logs and backups.

![Architecture Diagram](infrastructure/architecture.png)

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

| Component | Status | Notes |
|-----------|--------|-------|
| AWS Infrastructure (VPC, ALB, EC2, RDS, S3, IAM) | ✅ Complete | Modular Terraform, 2 AZs, private data tier |
| Containerized Flask API | ✅ Complete | 3 endpoints: /health, /data, /drift |
| Drift Detector | ✅ Complete | Detects missing, changed, and unexpected resources |
| CI/CD GitHub Actions (Terraform) | ✅ Complete | fmt → validate → plan on every push |
| CI/CD GitHub Actions (Docker) | ✅ Complete | CI on PR: build without push → CD on merge: build & push to Docker Hub |
| Architecture Diagram | ✅ Complete | Draw.io diagram with CIDRs and traffic flow |
| IMDSv2 Enforcement | ✅ Complete | Blocks SSRF-based credential theft via EC2 metadata service |

---

## 🛠 Stack

- **Terraform** — Infrastructure as Code
- **AWS** — VPC, EC2, RDS, S3, ALB, IAM
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

---

## 🔮 Future Improvements

- [x] CI/CD Docker workflow (build + push to Docker Hub)
- [x] IMDSv2 enforcement on EC2 instances
- [x] IAM Hardening: least privilege policies, TLS conditions, bucket policies
- [ ] Connect Flask API to RDS PostgreSQL for persistent storage
- [ ] Add NAT Gateway for private subnet outbound access
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
