resource "aws_secretsmanager_secret" "rds_credentials" {
  name        = "${var.project_name}-rds-credentials"
  description = "RDS PostgreSQL credentials for TechFlow API"

  tags = {
    Name = "${var.project_name}-rds-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id

  secret_string = jsonencode({
    host     = split(":", var.rds_endpoint)[0]
    port     = "5432"
    dbname   = "techflowdb"
    username = "adminLean"
    password = var.db_password
  })
}
