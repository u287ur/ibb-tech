# Listener for the Public ALB
# Routes HTTP requests on port 80 to the Frontend Target Group
resource "aws_lb_listener" "frontend_listener" {
  load_balancer_arn = aws_lb.frontend_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }

  depends_on = [aws_lb_target_group.frontend_tg]
}

# Listener for the Internal ALB
# Routes HTTP requests on port 80 to the Backend Target Group
resource "aws_lb_listener" "backend_listener" {
  load_balancer_arn = aws_lb.backend_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }

  depends_on = [aws_lb_target_group.backend_tg]
}
