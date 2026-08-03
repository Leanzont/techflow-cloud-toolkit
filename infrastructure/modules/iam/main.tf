# IAM Role 
resource "aws_iam_role" "role_ec2" {
  name = "${var.project_name}-role-ec2"

  # Trust Policy
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-role-ec2"
  }
}


# IAM Policy

resource "aws_iam_role_policy" "s3_policy" {
  name = "${var.project_name}-s3-policy"
  role = aws_iam_role.role_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.log_bucket_arn,
          var.backups_bucket_arn,
          "${var.log_bucket_arn}/*",
          "${var.backups_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Instance Profile 

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.role_ec2.name
}
