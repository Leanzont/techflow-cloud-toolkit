output "ec2_public_ip" {
  description = "instance public ip"
  value       = module.ec2.public_ip
}

output "log_bucket_name_s3" {
  description = "Log Bucket"
  value       = module.s3.log_bucket_name
}

output "backups_buket_name_s3" {
  description = "Backups Bucket"
  value       = module.s3.backups_bucket_name
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.rds_endpoint
}
