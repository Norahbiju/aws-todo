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

variable "image_manifest_parameter_name" {
  description = "SSM String parameter containing frontend and backend digest-pinned image references as JSON."
  type        = string
}

variable "task_cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Fargate task memory in MiB."
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Initial ECS service desired count before Application Auto Scaling manages it."
  type        = number
  default     = 1
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

variable "tags" {
  description = "Additional tags applied to all supported resources."
  type        = map(string)
  default     = {}
}

