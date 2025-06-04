output "frontend_alb_dns" {
  value = aws_lb.frontend_alb.dns_name
}

output "backend_alb_dns" {
  value = aws_lb.backend_alb.dns_name
}

output "vpc_id" {
  value = module.custom_vpc.vpc_id
}

output "public_subnets" {
  value = module.custom_vpc.public_subnets
}

output "private_subnets" {
  value = module.custom_vpc.private_subnets
}

output "jenkins_sg_id" {
  value = aws_security_group.jenkins_sg.id
}

output "jenkins_public_ip" {
  description = "Jenkins Public IP adress"
  value       = aws_instance.jenkins.public_ip
}

output "backend_sg_id" {
  value = aws_security_group.backend_sg.id
}

output "frontend_sg_id" {
  value = aws_security_group.frontend_sg.id
}

output "backend_tg_arn" {
  value = aws_lb_target_group.backend_tg.arn
}

output "frontend_tg_arn" {
  value = aws_lb_target_group.frontend_tg.arn
}