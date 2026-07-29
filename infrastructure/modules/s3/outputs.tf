output "log_bucket_arn" {
  value = aws_s3_bucket.log_bucket.arn
}

output "backups_bucket_arn" {
  value = aws_s3_bucket.backups_bucket.arn
}

output "log_bucket_name" {
  value = aws_s3_bucket.log_bucket.bucket
}

output "backups_bucket_name" {
  value = aws_s3_bucket.backups_bucket.bucket
}
