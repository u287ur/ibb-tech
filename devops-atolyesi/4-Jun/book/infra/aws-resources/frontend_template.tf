resource "aws_launch_template" "frontend_lt" {
  name          = "frontend-template"
  image_id      = var.ami_id
  instance_type = "t3.micro"
  key_name      = var.key_name

  vpc_security_group_ids = [
    data.terraform_remote_state.jenkins.outputs.frontend_sg_id
  ]

  user_data = base64encode(templatefile("${path.module}/userdata/frontend.sh", {
    frontend_alb_dns    = data.terraform_remote_state.jenkins.outputs.frontend_alb_dns,
    backend_alb_dns     = data.terraform_remote_state.jenkins.outputs.backend_alb_dns,
    dockerhub_username  = var.dockerhub_username,
    dockerhub_password  = var.dockerhub_password,
    frontend_image_tag  = var.frontend_image_tag
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "frontend-instance"
    }
  }
}
