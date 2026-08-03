# Security Groutp RDS
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "allow db for my EC2"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Security group PostgresSQL"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.sg_ec2_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# DB Subnet Group 
resource "aws_db_subnet_group" "db_group" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-subnet-group"
  }
}

# RDS PostgresSQL
resource "aws_db_instance" "postgres" {
  identifier        = "${var.project_name}-postgressql"
  engine            = "postgres"
  engine_version    = "18.4"
  instance_class    = "db.t3.micro"
  allocated_storage = 10

  db_name  = "techflowdb"
  username = "adminLean"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.db_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
}
