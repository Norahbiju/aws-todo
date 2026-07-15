include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../modules/ecs-todo"
}

inputs = {
  environment                   = "dev"
  expected_account_id           = get_env("AWS_ACCOUNT_ID_DEV")
  image_manifest_parameter_name = get_env("SSM_IMAGE_PARAMETER_NAME", "/ecs-todo/container-images")
  vpc_cidr                      = "10.10.0.0/16"
  public_subnet_cidrs           = ["10.10.0.0/24", "10.10.1.0/24"]
  private_subnet_cidrs          = ["10.10.10.0/24", "10.10.11.0/24"]
  nat_gateway_count             = 2
  log_retention_days            = 14
}

