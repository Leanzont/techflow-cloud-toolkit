variable "project_name" {
  type = string
}

variable "log_bucket_arn" {
  type = string
}

variable "backups_bucket_arn" {
  type = string
}

variable "secret_arn" {
  type        = string
  description = "ARN of the Secrets Manager secret for RDS credentials"
}
