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
      cpu          = 256
      memory       = 512
      portMappings = [{ containerPort = 3000, hostPort = 3000, protocol = "tcp" }]
      environment  = [{ name = "NODE_ENV", value = "production" }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "wget -q -O /dev/null http://127.0.0.1:3000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 20
      }
    },
    {
      name         = "backend"
      image        = local.backend_image
      essential    = true
      cpu          = 256
      memory       = 512
      portMappings = [{ containerPort = 8000, hostPort = 8000, protocol = "tcp" }]
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
        command     = ["CMD-SHELL", "python -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/api/health', timeout=3)\" || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 20
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
  platform_version                   = "LATEST"
  health_check_grace_period_seconds  = 90
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
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
    container_port   = 3000
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 8000
  }
  lifecycle { ignore_changes = [desired_count] }
  depends_on = [aws_lb_listener.http, aws_lb_listener_rule.api]
}

