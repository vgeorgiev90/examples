output "elb_dns_name" {
  value = aws_lb.app.dns_name
}

output "alb_arn" {
  value = aws_lb.app.arn
}

output "ecs_target_group_arn" {
  value = aws_lb_target_group.ecs-app.arn
}
