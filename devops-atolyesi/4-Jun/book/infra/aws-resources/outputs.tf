output "rds_endpoint" {
  value = aws_db_instance.mysql.endpoint
}
output "backend_alb_dns" {
  value = data.terraform_remote_state.jenkins.outputs.backend_alb_dns
}
output "frontend_alb_dns" {
  value = data.terraform_remote_state.jenkins.outputs.frontend_alb_dns
}