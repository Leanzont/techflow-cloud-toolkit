# TechFlow Cloud Toolkit

This project solves a real cloud operations problem: how do you know your live 
AWS resources still match what you declared in code? I built a complete cloud 
stack from scratch — Terraform modules for networking and compute, a Dockerized 
Flask API, and a custom Python tool that detects infrastructure drift by 
comparing live AWS state against YAML configuration.

## Current Status

- [x] AWS Infrastructure (VPC, ALB, EC2, RDS, S3, IAM)
- [ ] Dockerized Flask API (3 endpoints)
- [x] Drift Detector
- [x] CI/CD GitHub Actions
- [ ] Architecture diagram

## Stack

- Terraform
- AWS (EC2, RDS, S3, ALB, IAM, VPC)
- Python / Boto3
- Docker
- Flask


