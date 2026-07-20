variable "project_name" {
  description = "Short lowercase name used to identify application resources."
  type        = string
  default     = "ecs-todo"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.project_name))
    error_message = "project_name must be 2-21 lowercase letters, digits, or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}

variable "expected_account_id" {
  description = "Twelve-digit AWS account ID that the provider is permitted to modify."
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.expected_account_id))
    error_message = "expected_account_id must contain exactly 12 digits."
  }
}

variable "aws_region" {
  description = "AWS region in which application resources are created."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR for the VPC."
  type        = string
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR."
  }
}

variable "public_subnet_cidrs" {
  description = "Exactly two public subnet CIDRs, one per availability zone."
  type        = list(string)
  validation {
    condition     = length(var.public_subnet_cidrs) == 2 && alltrue([for cidr in var.public_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "public_subnet_cidrs must contain exactly two valid CIDRs."
  }
}

variable "private_subnet_cidrs" {
  description = "Exactly two private subnet CIDRs, one per availability zone."
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_cidrs) == 2 && alltrue([for cidr in var.private_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "private_subnet_cidrs must contain exactly two valid CIDRs."
  }
}

variable "availability_zones" {
  description = "Optional explicit pair of AZ names; the first two available AZs are used when empty."
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.availability_zones) == 0 || length(var.availability_zones) == 2
    error_message = "availability_zones must be empty or contain exactly two AZs."
  }
}

variable "nat_gateway_count" {
  description = "Number of NAT gateways. Use 2 for HA (default); 1 is a cost option for non-production."
  type        = number
  default     = 2
  validation {
    condition     = contains([1, 2], var.nat_gateway_count)
    error_message = "nat_gateway_count must be 1 or 2."
  }
}

variable "alb_listener_port" {
  description = "Public HTTP port exposed by the Application Load Balancer."
  type        = number
  default     = 80
  validation {
    condition     = var.alb_listener_port >= 1 && var.alb_listener_port <= 65535
    error_message = "alb_listener_port must be between 1 and 65535."
  }
}

variable "frontend_container_port" {
  description = "Frontend container and target-group port; it must match the port exposed by the frontend image."
  type        = number
  default     = 3000
  validation {
    condition     = var.frontend_container_port >= 1 && var.frontend_container_port <= 65535
    error_message = "frontend_container_port must be between 1 and 65535."
  }
}

variable "backend_container_port" {
  description = "Backend container and target-group port; it must match the port exposed by the backend image."
  type        = number
  default     = 8000
  validation {
    condition     = var.backend_container_port >= 1 && var.backend_container_port <= 65535
    error_message = "backend_container_port must be between 1 and 65535."
  }
}

variable "api_listener_rule_priority" {
  description = "Priority assigned to the ALB listener rule that routes API requests."
  type        = number
  default     = 100
  validation {
    condition     = var.api_listener_rule_priority >= 1 && var.api_listener_rule_priority <= 50000
    error_message = "api_listener_rule_priority must be between 1 and 50000."
  }
}

variable "api_path_patterns" {
  description = "ALB path patterns forwarded to the backend target group."
  type        = list(string)
  default     = ["/api/*"]
  validation {
    condition     = length(var.api_path_patterns) > 0 && alltrue([for pattern in var.api_path_patterns : startswith(pattern, "/")])
    error_message = "api_path_patterns must contain at least one path beginning with /."
  }
}

variable "target_deregistration_delay_seconds" {
  description = "Seconds the ALB waits for in-flight requests when deregistering a target."
  type        = number
  default     = 30
  validation {
    condition     = var.target_deregistration_delay_seconds >= 0 && var.target_deregistration_delay_seconds <= 3600
    error_message = "target_deregistration_delay_seconds must be between 0 and 3600."
  }
}

variable "frontend_health_check_path" {
  description = "Frontend ALB health-check path."
  type        = string
  default     = "/health"
  validation {
    condition     = startswith(var.frontend_health_check_path, "/")
    error_message = "frontend_health_check_path must begin with /."
  }
}

variable "backend_health_check_path" {
  description = "Backend ALB and container health-check path."
  type        = string
  default     = "/api/health"
  validation {
    condition     = startswith(var.backend_health_check_path, "/")
    error_message = "backend_health_check_path must begin with /."
  }
}

variable "alb_health_check_interval_seconds" {
  description = "Seconds between ALB target health checks."
  type        = number
  default     = 30
  validation {
    condition     = var.alb_health_check_interval_seconds >= 5 && var.alb_health_check_interval_seconds <= 300
    error_message = "alb_health_check_interval_seconds must be between 5 and 300."
  }
}

variable "alb_health_check_timeout_seconds" {
  description = "Seconds before an ALB target health check times out."
  type        = number
  default     = 5
  validation {
    condition     = var.alb_health_check_timeout_seconds >= 2 && var.alb_health_check_timeout_seconds <= 120 && var.alb_health_check_timeout_seconds < var.alb_health_check_interval_seconds
    error_message = "alb_health_check_timeout_seconds must be between 2 and 120 and less than the interval."
  }
}

variable "alb_healthy_threshold" {
  description = "Consecutive successful ALB health checks required to mark a target healthy."
  type        = number
  default     = 2
  validation {
    condition     = var.alb_healthy_threshold >= 2 && var.alb_healthy_threshold <= 10
    error_message = "alb_healthy_threshold must be between 2 and 10."
  }
}

variable "alb_unhealthy_threshold" {
  description = "Consecutive failed ALB health checks required to mark a target unhealthy."
  type        = number
  default     = 3
  validation {
    condition     = var.alb_unhealthy_threshold >= 2 && var.alb_unhealthy_threshold <= 10
    error_message = "alb_unhealthy_threshold must be between 2 and 10."
  }
}

variable "alb_health_check_matcher" {
  description = "HTTP status code or range that ALB health checks consider successful."
  type        = string
  default     = "200"
  validation {
    condition     = length(trimspace(var.alb_health_check_matcher)) > 0
    error_message = "alb_health_check_matcher cannot be empty."
  }
}

variable "image_manifest_parameter_name" {
  description = "SSM String parameter containing frontend and backend digest-pinned image references as JSON."
  type        = string
}

variable "task_cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 512
  validation {
    condition     = var.task_cpu > 0
    error_message = "task_cpu must be greater than zero."
  }
}

variable "task_memory" {
  description = "Fargate task memory in MiB."
  type        = number
  default     = 1024
  validation {
    condition     = var.task_memory > 0
    error_message = "task_memory must be greater than zero."
  }
}

variable "frontend_container_cpu" {
  description = "CPU units reserved for the frontend container within the Fargate task."
  type        = number
  default     = 256
  validation {
    condition     = var.frontend_container_cpu > 0
    error_message = "frontend_container_cpu must be greater than zero."
  }
}

variable "frontend_container_memory" {
  description = "Hard memory limit in MiB for the frontend container."
  type        = number
  default     = 512
  validation {
    condition     = var.frontend_container_memory > 0
    error_message = "frontend_container_memory must be greater than zero."
  }
}

variable "backend_container_cpu" {
  description = "CPU units reserved for the backend container within the Fargate task."
  type        = number
  default     = 256
  validation {
    condition     = var.backend_container_cpu > 0
    error_message = "backend_container_cpu must be greater than zero."
  }
}

variable "backend_container_memory" {
  description = "Hard memory limit in MiB for the backend container."
  type        = number
  default     = 512
  validation {
    condition     = var.backend_container_memory > 0
    error_message = "backend_container_memory must be greater than zero."
  }
}

variable "backend_health_check_interval_seconds" {
  description = "Seconds between ECS backend container health checks."
  type        = number
  default     = 30
  validation {
    condition     = var.backend_health_check_interval_seconds >= 5 && var.backend_health_check_interval_seconds <= 300
    error_message = "backend_health_check_interval_seconds must be between 5 and 300."
  }
}

variable "backend_health_check_timeout_seconds" {
  description = "Seconds before the ECS backend container health check times out."
  type        = number
  default     = 5
  validation {
    condition     = var.backend_health_check_timeout_seconds >= 2 && var.backend_health_check_timeout_seconds <= 60 && var.backend_health_check_timeout_seconds < var.backend_health_check_interval_seconds
    error_message = "backend_health_check_timeout_seconds must be between 2 and 60 and less than the interval."
  }
}

variable "backend_health_check_request_timeout_seconds" {
  description = "HTTP request timeout used inside the backend container health-check command."
  type        = number
  default     = 3
  validation {
    condition     = var.backend_health_check_request_timeout_seconds > 0 && var.backend_health_check_request_timeout_seconds <= var.backend_health_check_timeout_seconds
    error_message = "backend_health_check_request_timeout_seconds must be greater than zero and no more than backend_health_check_timeout_seconds."
  }
}

variable "backend_health_check_retries" {
  description = "Consecutive ECS backend container health-check failures required to mark it unhealthy."
  type        = number
  default     = 3
  validation {
    condition     = var.backend_health_check_retries >= 1 && var.backend_health_check_retries <= 10
    error_message = "backend_health_check_retries must be between 1 and 10."
  }
}

variable "backend_health_check_start_period_seconds" {
  description = "Grace period before ECS backend container health-check failures count."
  type        = number
  default     = 20
  validation {
    condition     = var.backend_health_check_start_period_seconds >= 0 && var.backend_health_check_start_period_seconds <= 300
    error_message = "backend_health_check_start_period_seconds must be between 0 and 300."
  }
}

variable "desired_count" {
  description = "Initial ECS service desired count before Application Auto Scaling manages it."
  type        = number
  default     = 1
  validation {
    condition     = var.desired_count >= 1
    error_message = "desired_count must be at least 1."
  }
}

variable "fargate_platform_version" {
  description = "Fargate platform version used by the ECS service."
  type        = string
  default     = "LATEST"
  validation {
    condition     = var.fargate_platform_version == "LATEST" || can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.fargate_platform_version))
    error_message = "fargate_platform_version must be LATEST or a version such as 1.4.0."
  }
}

variable "service_health_check_grace_period_seconds" {
  description = "Seconds ECS ignores load-balancer health failures after a task starts."
  type        = number
  default     = 90
  validation {
    condition     = var.service_health_check_grace_period_seconds >= 0
    error_message = "service_health_check_grace_period_seconds cannot be negative."
  }
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum percentage of desired ECS tasks kept healthy during a deployment."
  type        = number
  default     = 50
  validation {
    condition     = var.deployment_minimum_healthy_percent >= 0 && var.deployment_minimum_healthy_percent <= 100
    error_message = "deployment_minimum_healthy_percent must be between 0 and 100."
  }
}

variable "deployment_maximum_percent" {
  description = "Maximum percentage of desired ECS tasks allowed during a deployment."
  type        = number
  default     = 200
  validation {
    condition     = var.deployment_maximum_percent >= 100 && var.deployment_maximum_percent <= 200
    error_message = "deployment_maximum_percent must be between 100 and 200."
  }
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of ECS tasks."
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of ECS tasks."
  type        = number
  default     = 4
}

variable "autoscaling_cpu_target" {
  description = "Average service CPU target percentage."
  type        = number
  default     = 60
  validation {
    condition     = var.autoscaling_cpu_target > 0 && var.autoscaling_cpu_target <= 100
    error_message = "autoscaling_cpu_target must be greater than 0 and no more than 100."
  }
}

variable "autoscaling_scale_in_cooldown_seconds" {
  description = "Seconds Application Auto Scaling waits before another scale-in action."
  type        = number
  default     = 300
  validation {
    condition     = var.autoscaling_scale_in_cooldown_seconds >= 0
    error_message = "autoscaling_scale_in_cooldown_seconds cannot be negative."
  }
}

variable "autoscaling_scale_out_cooldown_seconds" {
  description = "Seconds Application Auto Scaling waits before another scale-out action."
  type        = number
  default     = 60
  validation {
    condition     = var.autoscaling_scale_out_cooldown_seconds >= 0
    error_message = "autoscaling_scale_out_cooldown_seconds cannot be negative."
  }
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period."
  type        = number
  default     = 30
}

variable "alarm_sns_topic_arn" {
  description = "Optional existing SNS topic ARN used for alarm and OK actions."
  type        = string
  default     = null
  nullable    = true
}

variable "alarm_period_seconds" {
  description = "CloudWatch alarm metric evaluation period in seconds."
  type        = number
  default     = 60
  validation {
    condition     = var.alarm_period_seconds >= 60 && var.alarm_period_seconds % 60 == 0
    error_message = "alarm_period_seconds must be 60 or a larger multiple of 60 for these standard-resolution AWS metrics."
  }
}

variable "alarm_evaluation_periods" {
  description = "Number of metric periods evaluated by each CloudWatch alarm."
  type        = number
  default     = 1
  validation {
    condition     = var.alarm_evaluation_periods >= 1
    error_message = "alarm_evaluation_periods must be at least 1."
  }
}

variable "alarm_datapoints_to_alarm" {
  description = "Number of breaching datapoints required to enter the CloudWatch ALARM state."
  type        = number
  default     = 1
  validation {
    condition     = var.alarm_datapoints_to_alarm >= 1 && var.alarm_datapoints_to_alarm <= var.alarm_evaluation_periods
    error_message = "alarm_datapoints_to_alarm must be between 1 and alarm_evaluation_periods."
  }
}

variable "http_5xx_alarm_threshold" {
  description = "Number of ALB or target 5xx responses that must be exceeded during an alarm period."
  type        = number
  default     = 10
  validation {
    condition     = var.http_5xx_alarm_threshold >= 0
    error_message = "http_5xx_alarm_threshold cannot be negative."
  }
}

variable "tags" {
  description = "Additional tags applied to all supported resources."
  type        = map(string)
  default     = {}
}
