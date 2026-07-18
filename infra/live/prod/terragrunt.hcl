include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../modules/ecs-todo"
}

inputs = {
  environment                   = "prod"
  expected_account_id           = get_env("AWS_ACCOUNT_ID_PROD")
  image_manifest_parameter_name = get_env("SSM_IMAGE_PARAMETER_NAME")
  vpc_cidr                      = "10.30.0.0/16"
  public_subnet_cidrs           = ["10.30.0.0/24", "10.30.1.0/24"]
  private_subnet_cidrs          = ["10.30.10.0/24", "10.30.11.0/24"]
  nat_gateway_count             = 2
  log_retention_days            = 90
}

