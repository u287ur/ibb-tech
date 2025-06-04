# Auto Scaling Group for Backend EC2 Instances
resource "aws_autoscaling_group" "backend_asg" {
  name                = "backend-asg"
  desired_capacity    = 1                     
  max_size            = 2                      
  min_size            = 1                      
  vpc_zone_identifier = data.terraform_remote_state.jenkins.outputs.private_subnets

  launch_template {
    id      = aws_launch_template.backend_lt.id
    version = aws_launch_template.backend_lt.latest_version
  }

  target_group_arns = [data.terraform_remote_state.jenkins.outputs.backend_tg_arn]  
  health_check_type = "EC2"

  tag {
    key                 = "Name"
    value               = "backend-instance"
    propagate_at_launch = true
  }
   timeouts {
    delete = "15m" 
  }

}

# Auto Scaling Group for Frontend EC2 Instances
resource "aws_autoscaling_group" "frontend_asg" {
  name                = "frontend-asg"
  desired_capacity    = 1                      
  max_size            = 2                      
  min_size            = 1                      
  vpc_zone_identifier = data.terraform_remote_state.jenkins.outputs.private_subnets

  launch_template {
    id      = aws_launch_template.frontend_lt.id
    version = aws_launch_template.frontend_lt.latest_version
  }

  target_group_arns = [data.terraform_remote_state.jenkins.outputs.frontend_tg_arn]  
  health_check_type = "EC2"

  tag {
    key                 = "Name"
    value               = "frontend-instance"
    propagate_at_launch = true
  }
   timeouts {
    delete = "15m"  
  }
}
