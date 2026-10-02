# Security Group  
resource "aws_security_group" "sg_ec2" {
  name        = "${var.project_name}-sg-ec2"
  description = "my seurity group ec2 SSH, HTTP"
  vpc_id      = var.vpc_id


  egress {
    description = "HTTP outbound for Docker and AWS services"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "DNS outbound"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-ec2"
  }

}

# Key Pair 
resource "aws_key_pair" "my_key_ec2" {
  count      = var.public_key != "" ? 1 : 0
  key_name   = "${var.project_name}-key"
  public_key = var.public_key
}


# EC2 Instance 
resource "aws_instance" "instance_ec2_techflow" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.sg_ec2.id]
  key_name               = null # SSM replaces SSH — no key pair needed
  iam_instance_profile   = var.instance_profile

  # IMDSv2: Enforce session token, block SSRF
  metadata_options {
    http_tokens                 = "required"
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user

              # SSM Agent is pre-installed on Amazon Linux 2
              # Ensure it is running and enabled
              systemctl enable amazon-ssm-agent
              systemctl start amazon-ssm-agent

              # Read RDS credentials from Secrets Manager
              SECRET=$(aws secretsmanager get-secret-value \
                --secret-id ${var.secret_name} \
                --region us-east-2 \
                --query SecretString \
                --output text)

              DB_HOST=$(echo $SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['host'])")
              DB_PORT=$(echo $SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['port'])")
              DB_NAME=$(echo $SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['dbname'])")
              DB_USER=$(echo $SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['username'])")
              DB_PASS=$(echo $SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])")

              # Pull and run the Flask API container
              docker pull ${var.docker_image}
              docker run -d \
                --name techflow-api \
                --restart always \
                -p 80:5000 \
                -e DB_HOST=$DB_HOST \
                -e DB_PORT=$DB_PORT \
                -e DB_NAME=$DB_NAME \
                -e DB_USER=$DB_USER \
                -e DB_PASS=$DB_PASS \
                -e AWS_DEFAULT_REGION=us-east-2 \
                ${var.docker_image}
              EOF


  tags = {
    Name = "${var.project_name}-ec2-instance-techflow"
  }
}






