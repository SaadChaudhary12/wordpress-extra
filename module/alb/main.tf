################################################################################
# LOAD BALANCER
################################################################################

resource "aws_lb" "this" {
  name                        = var.lb_name
  internal                    = false
  load_balancer_type          = var.lb_type
  security_groups             = [var.security_group_id]
  subnets                     = var.subnet_ids
  enable_cross_zone_load_balancing = true
  drop_invalid_header_fields  = true
}

resource "aws_lb_target_group" "this" {
  vpc_id = var.vpc_id
  name   = var.target_group_name
  port   = var.app_port
  protocol = "HTTP"

  health_check {
    path = var.health_check_path
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# resource "aws_lb_target_group_attachment" "this" {
#   target_group_arn = aws_lb_target_group.this.arn
#   target_id        = var.instance_id
#   port             = var.app_port
# }
