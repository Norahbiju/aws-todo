data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_partition" "current" {}

data "aws_ssm_parameter" "container_images" {
  name = var.image_manifest_parameter_name
}

