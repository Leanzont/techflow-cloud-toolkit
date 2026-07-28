# TechFlow Cloud Toolkit

This project solves a real cloud operations problem: how do you know your live 
AWS resources still match what you declared in code? I built a complete cloud 
stack from scratch — Terraform modules for networking and compute, a Dockerized 
Flask API, and a custom Python tool that detects infrastructure drift by 
comparing live AWS state against YAML configuration.

## Estado actual

- [x] Infraestructura AWS (VPC, ALB, EC2, RDS, S3, IAM)
- [ ] API Flask dockerizada (3 endpoints)
- [ ] Drift detector (en progreso)
- [ ] CI/CD GitHub Actions
- [ ] Diagrama de arquitectura

## Stack

- Terraform
- AWS (EC2, RDS, S3, ALB, IAM, VPC)
- Python / Boto3
- Docker
- Flask

## Próximos pasos

Ver [roadmap técnico](./docs/roadmap.md) (próximamente).
