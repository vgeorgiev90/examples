###################### ECS definitions #####################

data "aws_subnet_ids" "private" {
  vpc_id = var.vpc_id
  tags = {
    Tier = "Private"
  }
}

locals {
  subnet_list = tolist(data.aws_subnet_ids.private.ids)
}


resource "aws_ecs_cluster" "app_ecs" {
  name = "ecs-${var.environment}"
  capacity_providers = ["FARGATE"]
  setting {
    name = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "ecs-${var.environment}"
    Environment = var.environment
  }
}


resource "aws_ecs_task_definition" "application_task" {
  family = "wagtail"
  container_definitions = templatefile("${path.module}/tasks/ecs_task.tpl", {memory = var.memory, cpu = var.cpu, log_group = aws_cloudwatch_log_group.application.name, region = var.region, django_user = var.django_user, django_password = var.django_password, django_email = var.django_email, application_image = var.application_image, database_host = var.database_host, database_user = var.database_user, database_name = var.database_name})

  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  memory = var.memory
  cpu = var.cpu
  execution_role_arn = var.ecs_role
  task_role_arn = var.ecs_role

  tags = {
    Name = "ecs-task-${var.environment}"
    Environment = var.environment
  }
}


resource "aws_ecs_service" "ecs_service" {
  name = "wagtail-${var.environment}"
  cluster = aws_ecs_cluster.app_ecs.id
  task_definition = aws_ecs_task_definition.application_task.arn
  desired_count = 1
  launch_type = "FARGATE"
  force_new_deployment = true

  lifecycle {
    ignore_changes = [desired_count]
  }

  network_configuration {
    subnets = local.subnet_list
    security_groups = [ var.ecs_sg ]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.ecs_target_group
    container_name = "wagtail"
    container_port = 8000
  }
}


######################## Cloudwatch log group for our task #################

resource "aws_cloudwatch_log_group" "application" {
  name_prefix = "ecs_task-wagtail-${var.environment}"
  retention_in_days = 3

  tags = {
    Environment = var.environment
  }
}
