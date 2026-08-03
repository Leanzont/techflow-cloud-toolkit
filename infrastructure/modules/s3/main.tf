resource "aws_s3_bucket" "log_bucket" {
  bucket = var.s3_bucket_name_log

  tags = {
    Name = var.project_name
  }
}

resource "aws_s3_bucket" "backups_bucket" {
  bucket = var.s3_bucket_name_backups

  tags = {
    Name = var.project_name
  }
}

resource "aws_s3_bucket_public_access_block" "bucket_logs" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "bucket_backups" {
  bucket = aws_s3_bucket.backups_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
