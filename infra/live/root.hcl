locals {
  region       = get_env("AWS_REGION", "us-east-1")
  state_bucket = get_env("TF_STATE_BUCKET")
  kms_key_arn  = get_env("TF_STATE_KMS_KEY_ARN", "")
}

remote_state {
  backend = "s3"
  config = merge({
    bucket       = local.state_bucket
    key          = "ecs-todo/${path_relative_to_include()}/${local.region}/terraform.tfstate"
    region       = local.region
    encrypt      = true
    use_lockfile = true
  }, local.kms_key_arn == "" ? {} : { kms_key_id = local.kms_key_arn })

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

