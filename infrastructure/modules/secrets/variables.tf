variable "project_name" {
  type = string
}

variable "rds_endpoint" {
  type        = string
  description = "RDS endpoint from the rds module output"
}

variable "db_password" {
  type      = string
  sensitive = true
}
