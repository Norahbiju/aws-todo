# Infrastructure layout

`modules/ecs-todo` is the only Terraform root module. `live/dev`, `live/staging`, and `live/prod` are thin Terragrunt configurations that reuse it with account-specific inputs and isolated S3 keys. Infrastructure mutation is intentionally restricted to `.github/workflows/terraform.yml`; local use is limited to formatting, validation, and read-only inspection.

