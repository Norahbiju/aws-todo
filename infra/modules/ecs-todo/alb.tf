resource "aws_lb" "this" {
  name                       = substr(local.name, 0, 32)
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = aws_subnet.public[*].id
  drop_invalid_header_fields = true
  enable_deletion_protection = var.environment == "prod"
  tags                       = { Name = local.name }
}

resource "aws_lb_target_group" "frontend" {
  name                 = substr("${local.name}-front", 0, 32)
  port                 = var.frontend_container_port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = aws_vpc.this.id
  deregistration_delay = var.target_deregistration_delay_seconds
  health_check {
    enabled             = true
    path                = var.frontend_health_check_path
    healthy_threshold   = var.alb_healthy_threshold
    unhealthy_threshold = var.alb_unhealthy_threshold
    interval            = var.alb_health_check_interval_seconds
    timeout             = var.alb_health_check_timeout_seconds
    matcher             = var.alb_health_check_matcher
  }
}

resource "aws_lb_target_group" "backend" {
  name                 = substr("${local.name}-back", 0, 32)
  port                 = var.backend_container_port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = aws_vpc.this.id
  deregistration_delay = var.target_deregistration_delay_seconds
  health_check {
    enabled             = true
    path                = var.backend_health_check_path
    healthy_threshold   = var.alb_healthy_threshold
    unhealthy_threshold = var.alb_unhealthy_threshold
    interval            = var.alb_health_check_interval_seconds
    timeout             = var.alb_health_check_timeout_seconds
    matcher             = var.alb_health_check_matcher
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.alb_listener_port
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.http.arn
  priority     = var.api_listener_rule_priority
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
  condition {
    path_pattern { values = var.api_path_patterns }
  }
}
