output "alb_dns_name" {
  value = aws_lb.techflow_alb.dns_name
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "alb_arn_suffix" {
  value = aws_lb.techflow_alb.arn_suffix
}

output "target_group_arn_suffix" {
  value = aws_lb_target_group.techflow_tg.arn_suffix
}
