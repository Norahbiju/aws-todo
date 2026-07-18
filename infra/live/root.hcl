locals {
  region       = get_env("AWS_REGION")
  state_bucket = get_env("TF_STATE_BUCKET")
}

remote_state {
  backend = "s3"
  config = {
    bucket       = local.state_bucket
    key          = "ecs-todo/${path_relative_to_include()}/${local.region}/terraform.tfstate"
    region       = local.region
    encrypt      = true
    use_lockfile = true
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = {
  aws_region   = local.region
  project_name = "ecs-todo"
  tags = {
    Repository = get_env("GITHUB_REPOSITORY", "OWNER/REPOSITORY")
    CostCenter = "platform-demo"
  }
}
