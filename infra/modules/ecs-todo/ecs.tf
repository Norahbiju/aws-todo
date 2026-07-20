resource "aws_ecs_cluster" "this" {
  name = local.name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${local.name}/frontend"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${local.name}/backend"
  retention_in_days = var.log_retention_days
}

resource "aws_ecs_task_definition" "this" {
  family                   = local.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  container_definitions = jsonencode([
    {
      name         = "frontend"
      image        = local.frontend_image
      essential    = true
      cpu          = var.frontend_container_cpu
      memory       = var.frontend_container_memory
      portMappings = [{ containerPort = var.frontend_container_port, hostPort = var.frontend_container_port, protocol = "tcp" }]
      environment  = [{ name = "NODE_ENV", value = "production" }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
    {
      name         = "backend"
      image        = local.backend_image
      essential    = true
      cpu          = var.backend_container_cpu
      memory       = var.backend_container_memory
      portMappings = [{ containerPort = var.backend_container_port, hostPort = var.backend_container_port, protocol = "tcp" }]
      environment  = [{ name = "APP_ENV", value = var.environment }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "python -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:${var.backend_container_port}${var.backend_health_check_path}', timeout=${var.backend_health_check_request_timeout_seconds})\" || exit 1"]
        interval    = var.backend_health_check_interval_seconds
        timeout     = var.backend_health_check_timeout_seconds
        retries     = var.backend_health_check_retries
        startPeriod = var.backend_health_check_start_period_seconds
      }
    }
  ])

  depends_on = [aws_iam_role_policy.execution_logs]
}

resource "aws_ecs_service" "this" {
  name                               = local.name
  cluster                            = aws_ecs_cluster.this.id
  task_definition                    = aws_ecs_task_definition.this.arn
  desired_count                      = var.desired_count
  launch_type                        = "FARGATE"
  platform_version                   = var.fargate_platform_version
  health_check_grace_period_seconds  = var.service_health_check_grace_period_seconds
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  wait_for_steady_state              = true
  enable_execute_command             = false

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = var.frontend_container_port
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = var.backend_container_port
  }
  lifecycle { ignore_changes = [desired_count] }
  depends_on = [aws_lb_listener.http, aws_lb_listener_rule.api]
}
