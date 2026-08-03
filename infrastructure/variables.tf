variable "project_name" {
  type = string
}
variable "region" {
  type = string
}

# variables for s3 
variable "bucket_name_log" {
  type = string
}

variable "bucket_name_backups" {
  type = string
}

variable "instance_type" {
  type = string
}
variable "db_password" {
  type      = string
  sensitive = true
}
