# Operations runbook

## Deploy and promote

Normal delivery is build once, promote by digest, then plan/apply. Merge tested code to main; confirm both images and dev SSM manifest; dispatch a dev plan; dispatch an approved dev apply; observe health. Promote the same references to staging and production using the image workflow, then independently plan and approve each account. Never rebuild during promotion.

Before approving, confirm workflow run/commit, target account, image digests, plan action counts, replacements, public exposure, IAM changes, state key, and cost impact. After apply, the workflow waits for ECS stability and prints outputs. Verify ALB `/health`, `/api/health`, CRUD, target health, service events, logs, alarm state, and autoscaling registration.

## Incident checks

For an outage, start with ALB target health and ECS service events. Compare desired/running/pending counts, stopped reasons, task definition digest, both container health checks, private routes/NAT, and CloudWatch logs. ALB-generated 5xx suggests routing/target availability; target-generated 5xx points to application failures. Preserve logs and CloudTrail evidence.

Rollback application content by promoting known-good immutable digests to the affected account, generating a new plan, and applying it through approval. Do not edit the ECS service or SSM parameter manually except under a separately documented emergency process; an SSM change alone does not change the running task until Terraform registers/applies a task definition.

## Routine maintenance

Regularly update dependencies and action SHAs through reviewed PRs, scan images, review IAM Access Analyzer/CloudTrail, test environment reviewers, inspect state versions and locks, audit package visibility, review budgets, validate alarms, and run controlled restore/rollback exercises. Prune neither plan artifacts nor state versions outside policy.

For scaling diagnostics inspect average CPU and scaling activity; remember data is intentionally inconsistent across tasks. For planned deletion use the exact destroy procedure in the setup guide. Local apply, targeted manual resource deletion, mutable tags, `-lock=false`, and console drift are prohibited.

References: [ECS troubleshooting](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/troubleshooting.html), [CloudWatch Logs Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AnalyzingLogData.html), [AWS Well-Architected operations](https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/welcome.html).

