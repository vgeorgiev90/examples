resource "aws_appautoscaling_target" "application_target" {
  max_capacity = var.max_capacity
  min_capacity = var.min_capacity
  resource_id = "service/${var.ecs_cluster}/${var.ecs_service}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
}

resource "aws_appautoscaling_policy" "application_memory" {
  name               = "ecs-memory-asp-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.application_target.resource_id
  scalable_dimension = aws_appautoscaling_target.application_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.application_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 80
  }
}

resource "aws_appautoscaling_policy" "application_cpu" {
  name = "ecs-cpu-asp-${var.environment}"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.application_target.resource_id
  scalable_dimension = aws_appautoscaling_target.application_target.scalable_dimension
  service_namespace = aws_appautoscaling_target.application_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 60
  }
}
