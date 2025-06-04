resource "aws_launch_template" "backend_lt" {
  name          = "backend-template"
  image_id      = var.ami_id
  instance_type = "t3.micro"
  key_name      = var.key_name

  vpc_security_group_ids = [
    data.terraform_remote_state.jenkins.outputs.backend_sg_id
  ]

  user_data = base64encode(templatefile("${path.module}/userdata/backend.sh", {
    backend_alb_dns     = data.terraform_remote_state.jenkins.outputs.backend_alb_dns,
    dockerhub_username  = var.dockerhub_username,
    dockerhub_password  = var.dockerhub_password,
    backend_image_tag   = var.backend_image_tag,
    db_username         = var.db_username,
    db_password         = var.db_password,
    rds_endpoint        = aws_db_instance.mysql.address,
    secret_key          = var.secret_key
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "backend-instance"
    }
  }
  depends_on = [aws_db_instance.mysql]
}
