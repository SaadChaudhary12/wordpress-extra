resource "aws_launch_template" "this" {
  name          = var.launch_template_name
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = var.security_groups
  }

  iam_instance_profile {
  name = var.iam_instance_profile_name
  }

  user_data = base64encode(var.user_data)
}

resource "aws_autoscaling_group" "this" {
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  vpc_zone_identifier = var.subnets

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
  target_group_arns = var.target_group_arns

  tag {
    key                 = "Name"
    value               = "App-instance"
    propagate_at_launch = true
  }
}
