# Load Balancer 
resource "aws_lb" "techflow_alb" {
  name               = "${var.project_name}-alb"
  internal           = false 
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids
}

# Target Group
resource "aws_lb_target_group" "techflow_tg" {
   name     = "${var.project_name}-tg"
   port     = 80 
   protocol = "HTTP"
   vpc_id   = var.vpc_id

   health_check {
     path = "/health"
   }
}

#Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.techflow_alb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.techflow_tg.arn
  }
}

# security_group
resource "aws_security_group" "alb_sg" {
   name = "${var.project_name}-alb-sg"
   description = "allow HTTP from internet to ALB"
   vpc_id = var.vpc_id

   ingress {
     description = "HTTP from internet"
     to_port     = 80
     from_port    = 80
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }

   egress {
     to_port     = 0 
     from_port   = 0
     protocol    = "-1"
     cidr_blocks = ["0.0.0.0/0"]
   }
}

# Target Group Attachment for connect my ALB to my EC2
resource "aws_lb_target_group_attachment" "ec2" {
   target_group_arn = aws_lb_target_group.techflow_tg.arn
   target_id        = var.ec2_instance_id
   port             = 80
}
