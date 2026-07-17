# Setup guide

This is the one-time setup sequence. AWS deployment roles, shared state storage, and GitHub administration are prerequisites; this repository does not create them. Replace every `<PLACEHOLDER>` before the first pipeline run. Never bypass the workflow with local apply/destroy.

## 1. Local and repository prerequisites

Install Git, Node.js 22, npm, Python 3.13, Docker, Terraform 1.15.5, Terragrunt 1.0.4, AWS CLI v2, and optionally TFLint/actionlint. Create a GitHub repository, commit this tree, set `main` as default, and enable Actions with package-write access. Keep default `GITHUB_TOKEN` permissions minimal; each workflow declares its needs.

Protect main using a ruleset: require PR review, conversation resolution, and CODEOWNERS approval; block force pushes/deletion. Protect workflow and infrastructure paths. The current workflows do not run on pull requests, so introduce separate non-deployment PR checks before marking application or Terraform checks as required. Enable secret scanning, dependency alerts, and immutable release/package policies appropriate to the organisation.

## 2. Shared state bucket

In the designated shared-services or target account, create `<TF_STATE_BUCKET>` outside this module. Enable Block Public Access, versioning, default SSE-S3 or SSE-KMS encryption, and TLS-only bucket access. Do not configure object lifecycle to delete current state or fresh noncurrent versions.

Grant all three deployment roles `s3:ListBucket` for `ecs-todo/*` plus object get/put/delete on `ecs-todo/*/terraform.tfstate` and `.tflock`. Scope each role further to its own account alias when possible. If using `<TF_STATE_KMS_KEY_ARN>`, the role policy and KMS key policy must allow encrypt/decrypt/data-key/describe through S3 for this bucket. Test with read-only `aws s3api head-bucket` and a controlled backend init, not an apply.

## 3. GitHub OIDC roles

Create the GitHub OIDC provider and one existing deployment role per AWS account. Trust `aud=sts.amazonaws.com` and this repository's exact immutable subject: `repo:Norahbiju@262330368/aws-todo@1301448178:ref:refs/heads/main`. See [GitHub OIDC](github-oidc-aws.md) for the format. GitHub Environments are not used. For stronger production separation later, use distinct plan and deployment roles with narrowly scoped permissions.

The deployment policy needs the shared backend, optional KMS, named SSM parameter, and project resource actions. The following is a policy shape, not a drop-in least-privilege final policy; replace placeholders, split plan and deploy roles if possible, apply resource-level constraints supported by each API, and refine with IAM Access Analyzer:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {"Sid":"StateList","Effect":"Allow","Action":"s3:ListBucket","Resource":"arn:aws:s3:::<TF_STATE_BUCKET>","Condition":{"StringLike":{"s3:prefix":["ecs-todo/<ENV>/*"]}}},
    {"Sid":"StateObjects","Effect":"Allow","Action":["s3:GetObject","s3:PutObject","s3:DeleteObject"],"Resource":["arn:aws:s3:::<TF_STATE_BUCKET>/ecs-todo/<ENV>/*/terraform.tfstate","arn:aws:s3:::<TF_STATE_BUCKET>/ecs-todo/<ENV>/*/terraform.tfstate.tflock"]},
    {"Sid":"Images","Effect":"Allow","Action":["ssm:GetParameter","ssm:PutParameter"],"Resource":"arn:aws:ssm:<REGION>:<ACCOUNT_ID>:parameter/ecs-todo/container-images"},
    {"Sid":"VpcResources","Effect":"Allow","Action":["ec2:Describe*","ec2:CreateVpc","ec2:ModifyVpcAttribute","ec2:DeleteVpc","ec2:CreateSubnet","ec2:ModifySubnetAttribute","ec2:DeleteSubnet","ec2:CreateRouteTable","ec2:DeleteRouteTable","ec2:CreateRoute","ec2:DeleteRoute","ec2:AssociateRouteTable","ec2:DisassociateRouteTable","ec2:CreateInternetGateway","ec2:DeleteInternetGateway","ec2:AttachInternetGateway","ec2:DetachInternetGateway","ec2:AllocateAddress","ec2:ReleaseAddress","ec2:CreateNatGateway","ec2:DeleteNatGateway","ec2:CreateSecurityGroup","ec2:DeleteSecurityGroup","ec2:AuthorizeSecurityGroupIngress","ec2:AuthorizeSecurityGroupEgress","ec2:RevokeSecurityGroupIngress","ec2:RevokeSecurityGroupEgress","ec2:CreateTags","ec2:DeleteTags"],"Resource":"*"},
    {"Sid":"LoadBalancing","Effect":"Allow","Action":["elasticloadbalancing:Describe*","elasticloadbalancing:CreateLoadBalancer","elasticloadbalancing:DeleteLoadBalancer","elasticloadbalancing:ModifyLoadBalancerAttributes","elasticloadbalancing:SetSecurityGroups","elasticloadbalancing:SetSubnets","elasticloadbalancing:CreateTargetGroup","elasticloadbalancing:DeleteTargetGroup","elasticloadbalancing:ModifyTargetGroupAttributes","elasticloadbalancing:ModifyTargetGroup","elasticloadbalancing:CreateListener","elasticloadbalancing:DeleteListener","elasticloadbalancing:ModifyListener","elasticloadbalancing:CreateRule","elasticloadbalancing:DeleteRule","elasticloadbalancing:ModifyRule","elasticloadbalancing:SetRulePriorities","elasticloadbalancing:RegisterTargets","elasticloadbalancing:DeregisterTargets","elasticloadbalancing:AddTags","elasticloadbalancing:RemoveTags"],"Resource":"*"},
    {"Sid":"EcsAndScaling","Effect":"Allow","Action":["ecs:Describe*","ecs:ListTagsForResource","ecs:CreateCluster","ecs:DeleteCluster","ecs:UpdateClusterSettings","ecs:RegisterTaskDefinition","ecs:DeregisterTaskDefinition","ecs:CreateService","ecs:UpdateService","ecs:DeleteService","ecs:TagResource","ecs:UntagResource","application-autoscaling:Describe*","application-autoscaling:RegisterScalableTarget","application-autoscaling:DeregisterScalableTarget","application-autoscaling:PutScalingPolicy","application-autoscaling:DeleteScalingPolicy"],"Resource":"*"},
    {"Sid":"Observability","Effect":"Allow","Action":["cloudwatch:DescribeAlarms","cloudwatch:PutMetricAlarm","cloudwatch:DeleteAlarms","cloudwatch:TagResource","cloudwatch:UntagResource","cloudwatch:ListTagsForResource","logs:DescribeLogGroups","logs:ListTagsForResource","logs:CreateLogGroup","logs:DeleteLogGroup","logs:PutRetentionPolicy","logs:TagResource","logs:UntagResource"],"Resource":"*"},
    {"Sid":"ProjectRoles","Effect":"Allow","Action":["iam:GetRole","iam:CreateRole","iam:DeleteRole","iam:TagRole","iam:UntagRole","iam:PutRolePolicy","iam:GetRolePolicy","iam:DeleteRolePolicy"],"Resource":"arn:aws:iam::<ACCOUNT_ID>:role/ecs-todo-<ENV>-*"},
    {"Sid":"PassOnlyToEcsTasks","Effect":"Allow","Action":"iam:PassRole","Resource":"arn:aws:iam::<ACCOUNT_ID>:role/ecs-todo-<ENV>-*","Condition":{"StringEquals":{"iam:PassedToService":"ecs-tasks.amazonaws.com"}}}
  ]
}
```

Some create/describe APIs require `Resource: "*"`; add request-tag and region conditions, then constrain post-create operations to exact ARN/tag patterns where AWS supports them. Separate `ssm:PutParameter` and mutation actions from Terraform plan roles. Validate the final policy against an actual plan with IAM Access Analyzer because provider releases can change the required read actions.

## 4. Repository variables

Create these non-secret repository or organisation variables:

| Variable | Value |
|---|---|
| `AWS_ROLE_ARN_DEV` | existing dev OIDC role ARN |
| `AWS_ACCOUNT_ID_DEV` | 12-digit dev account ID |
| `AWS_REGION` | deployment region, currently `ap-south-1` |
| `TF_STATE_BUCKET` | shared S3 bucket name |
| `TF_STATE_KMS_KEY_ARN` | KMS ARN or an empty value for bucket-default encryption |
| `SSM_IMAGE_PARAMETER_NAME` | `/ecs-todo/container-images` |

Optional future variables, required only when their targets are selected:

| Variable | Value |
|---|---|
| `AWS_ROLE_ARN_STAGING` | existing staging OIDC role ARN |
| `AWS_ROLE_ARN_PROD` | existing prod OIDC role ARN |
| `AWS_ACCOUNT_ID_STAGING` | 12-digit staging account ID |
| `AWS_ACCOUNT_ID_PROD` | 12-digit prod account ID |

Role ARNs and account IDs are identifiers, not credentials, but follow organisational variable/secrets policy. Do not add AWS access-key secrets.

All account IDs and role ARNs are repository variables; neither workflow hard-codes an account. GitHub repository variables are mapped into step-level process environment variables only where Bash, the AWS CLI, Terraform, or Terragrunt must consume them. This runtime mapping is not a GitHub Environment and does not create environment-scoped configuration.

No GitHub Environment is required. The workflows enforce `main` before AWS authentication or deployment. The optional workflow paths already exist, but staging and production variables and roles are not required until those targets are selected.

## 5. First publication and deployment

1. Merge the implementation to main. The container workflow builds and publishes both SHA-tagged images.
2. Open each package's GitHub page and choose **Package settings → Change visibility → Public**. The first ECS pull will fail while private.
3. Re-run the main image workflow after visibility is public. It assumes the dev role, verifies the dev account, and creates/updates the SSM JSON parameter.
4. Inspect the summary and compare both GHCR digests with `aws ssm get-parameter --name /ecs-todo/container-images --query Parameter.Value --output text` under authorised read-only credentials.
5. Dispatch Terraform with `action=plan,target=dev`. Review networking, IAM, image digests, costs, and outputs.
6. Dispatch `action=apply,target=dev` from main. Review the saved-plan summary; the second job verifies and applies that exact artifact without an environment approval gate.
7. Open `http://<alb_dns_name>` from the output and test create/edit/complete/delete. Check both target groups, ECS health, logs, and alarms.
8. When ready, configure staging or production variables, roles, and main-branch OIDC trust; the existing workflow target can then be selected without another workflow redesign.

## 6. Safe destruction

Dispatch Terraform from main with `action=destroy`, the desired target, and exact confirmation `DESTROY <target>`. Review the complete destroy text in the artifact/summary; the exact destroy plan then applies without an environment approval gate. Never force local deletion or disable locking.

References: [GitHub repository variables](https://docs.github.com/actions/learn-github-actions/variables), [package visibility](https://docs.github.com/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility), [S3 security](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html).
