variable "project_name" {
  type = string
}

variable "alert_email" {
  type        = string
  description = "Email address to receive CloudWatch alarm notifications"
}

variable "ec2_instance_id" {
  type        = string
  description = "EC2 instance ID to monitor"
}

variable "alb_arn_suffix" {
  type        = string
  description = "ALB ARN suffix for CloudWatch metrics (not the full ARN)"
}

variable "target_group_arn_suffix" {
  type        = string
  description = "Target group ARN suffix for ALB metrics"
}
