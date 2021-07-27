data "aws_subnet_ids" "public" {
  vpc_id = var.vpc_id
  tags = {
    Tier = "Public"
  }
}

locals {
  subnet_list = tolist(data.aws_subnet_ids.public.ids)
}


resource "aws_lb" "app" {
  name               = "ecs-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.load_balancer_sg]
  subnets            = local.subnet_list

  tags = {
    Name = "ecs-alb-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "ecs-app" {
  name     = "ecs-app-${var.environment}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    interval            = 300
    path                = "/"
    timeout             = 60
    matcher             = "200-399"
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }

  tags = {
    Name = "ecs-app-${var.environment}"
    Environment = var.environment
  }

}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs-app.arn
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
