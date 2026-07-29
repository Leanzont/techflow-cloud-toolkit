# Security Group  
resource "aws_security_group" "sg_ec2" {
  name        = "${var.project_name}-sg-ec2"
  description = "my seurity group ec2 SSH, HTTP"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH only my ip"
    to_port     = 22
    from_port   = 22
    protocol    = "tcp"
    cidr_blocks  = [var.my_ip]
  }

  ingress {
    description = "HTTP for the API"
    to_port     = 80
    from_port   = 80
    protocol    = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
  }
  
  egress {
    to_port = 0
    from_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# Key Pair 
resource "aws_key_pair" "my_key_ec2" {
   key_name = "my-key-techflow"
   public_key = file("~/techflow-cloud-toolkit/infrastructure/modules/ec2/my-key-techflow.pub")
}


# EC2 Instance 
resource "aws_instance" "instance_ec2_techflow" {
   ami                    = var.ami
   instance_type          = var.instance_type
   subnet_id              = var.subnet_id
   vpc_security_group_ids = [aws_security_group.sg_ec2.id]
   key_name               = aws_key_pair.my_key_ec2.key_name
   iam_instance_profile  = var.instance_profile

   user_data = <<-EOF
                  #!/bin/bash
                  yum update -y
                  yum install -y docker
                  systemctl start docker
                  systemctl enable docker
                  usermod -aG docker ec2-user
                  EOF
   tags = {
     Name = "${var.project_name}-ec2-instance-techflow"
   }
}






