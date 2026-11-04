output "secret_arn" {
  value = aws_secretsmanager_secret.rds_credentials.arn
}

output "secret_name" {
  value      = aws_secretsmanager_secret.rds_credentials.name
  depends_on = [aws_secretsmanager_secret_version.rds_credentials]
}
