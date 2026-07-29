output "instance_id" {
  value = aws_instance.instance_ec2_techflow.id
}

output "public_ip" {
  value = aws_instance.instance_ec2_techflow.public_ip
}

output "sg_ec2_id" {
  value = aws_security_group.sg_ec2.id
}
