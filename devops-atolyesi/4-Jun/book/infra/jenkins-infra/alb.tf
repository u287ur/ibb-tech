# Public Application Load Balancer for Frontend (exposed to the internet)
resource "aws_lb" "frontend_alb" {
  name               = "frontend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.custom_vpc.public_subnets 

  tags = {
    Name = "frontend-alb"
  }
}

# Internal Application Load Balancer for Backend (private VPC only)
resource "aws_lb" "backend_alb" {
  name               = "backend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.custom_vpc.public_subnets

  tags = {
    Name = "backend-alb"
  }
}

# Target Group for Frontend EC2 instances on port 8080
resource "aws_lb_target_group" "frontend_tg" {
  name     = "frontend-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = module.custom_vpc.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }
   stickiness {
    enabled = true                  
    type    = "lb_cookie"           
    cookie_duration = 300           
  }
}

# Target Group for Backend EC2 instances on port 8000
resource "aws_lb_target_group" "backend_tg" {
  name     = "backend-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = module.custom_vpc.vpc_id

  health_check {
    path                = "/api/health/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }
   stickiness {
    enabled = true                  
    type    = "lb_cookie"           
    cookie_duration = 300           
  }
}
