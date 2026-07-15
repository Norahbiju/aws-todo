# Terraform module

## Design

`infra/modules/ecs-todo` is the sole Terraform root module for all accounts. Files are split by concern but form one dependency graph. Inputs are typed, described, and validated; locals centralise naming and tags; ECS definitions use `jsonencode`; provider `allowed_account_ids` creates a second wrong-account guard.

Terraform is constrained to `>=1.10,<2.0`; CI pins 1.15.5 and AWS provider 6.53.0. The provider lock file records resolved hashes. The module uses no workspaces, provisioners, null resources, local state, hardcoded account IDs, or image URIs.

At plan time `aws_ssm_parameter.container_images` reads the existing JSON manifest. A check requires public GHCR digest references for both keys. Missing parameters fail data lookup; malformed JSON fails `jsondecode`; missing or mutable values fail the explicit check with instructions to run the image workflow. This deliberately places exact image digests in the saved plan.

## Safe use and verification

Terragrunt supplies provider inputs and remote backend. Locally, only run `terraform fmt -check -recursive infra`, `terraform -chdir=infra/modules/ecs-todo init -backend=false`, and `terraform validate`. Do not locally plan against shared accounts unless authorised, and never locally apply or destroy.

A validation success proves syntax and provider schema, not that AWS permissions, quotas, CIDRs, SSM data, or service startup are valid. Pipeline plans verify those account-bound facts. Review replacement operations, IAM policies, routes, public ingress, image digests, and cost-generating resources.

References: [Terraform modules](https://developer.hashicorp.com/terraform/language/modules/develop), [checks](https://developer.hashicorp.com/terraform/language/checks), [dependency lock file](https://developer.hashicorp.com/terraform/language/files/dependency-lock), [AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs).

