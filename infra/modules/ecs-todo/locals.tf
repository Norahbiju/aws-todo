locals {
  name = "${var.project_name}-${var.environment}"
  azs  = length(var.availability_zones) == 2 ? var.availability_zones : slice(sort(data.aws_availability_zones.available.names), 0, 2)

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })

  image_manifest = jsondecode(data.aws_ssm_parameter.container_images.value)
  frontend_image = try(local.image_manifest.frontend, "")
  backend_image  = try(local.image_manifest.backend, "")
  image_pattern  = "^ghcr\\.io/[a-z0-9_.-]+/[a-z0-9_.-]+@sha256:[a-f0-9]{64}$"

  alarm_actions = var.alarm_sns_topic_arn == null ? [] : [var.alarm_sns_topic_arn]
}

check "image_manifest_contract" {
  assert {
    condition = (
      can(local.image_manifest.frontend) &&
      can(local.image_manifest.backend) &&
      can(regex(local.image_pattern, local.frontend_image)) &&
      can(regex(local.image_pattern, local.backend_image))
    )
    error_message = "The SSM image manifest must contain digest-pinned public GHCR 'frontend' and 'backend' values. Run the container-image workflow first."
  }
}

check "capacity_bounds" {
  assert {
    condition = (
      var.autoscaling_min_capacity >= 1 &&
      var.autoscaling_max_capacity >= var.autoscaling_min_capacity &&
      var.desired_count >= var.autoscaling_min_capacity &&
      var.desired_count <= var.autoscaling_max_capacity
    )
    error_message = "Autoscaling capacity must have min >= 1 and max >= min, and desired_count must be within those bounds."
  }
}

check "container_resources_fit_task" {
  assert {
    condition = (
      var.frontend_container_cpu + var.backend_container_cpu <= var.task_cpu &&
      var.frontend_container_memory + var.backend_container_memory <= var.task_memory
    )
    error_message = "The combined frontend and backend CPU and memory allocations must fit within the Fargate task CPU and memory."
  }
}

check "container_ports_are_distinct" {
  assert {
    condition     = var.frontend_container_port != var.backend_container_port
    error_message = "frontend_container_port and backend_container_port must be different because both containers share one task network interface."
  }
}
