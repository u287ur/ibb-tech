# ✅ Backend CPU > 70% → Scale Out
resource "aws_autoscaling_policy" "backend_scale_out" {
  name                   = "backend-cpu-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.backend_asg.name
}

resource "aws_cloudwatch_metric_alarm" "backend_cpu_high" {
  alarm_name          = "backend-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 30
  alarm_description   = "Triggers scale out if CPU > 30%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.backend_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.backend_scale_out.arn]
}

# ✅ Backend CPU < 30% → Scale In
resource "aws_autoscaling_policy" "backend_scale_in" {
  name                   = "backend-cpu-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.backend_asg.name
}

resource "aws_cloudwatch_metric_alarm" "backend_cpu_low" {
  alarm_name          = "backend-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 30
  alarm_description   = "Triggers scale in if CPU < 30%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.backend_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.backend_scale_in.arn]
}
