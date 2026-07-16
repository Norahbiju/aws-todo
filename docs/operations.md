# Operations runbook

## Deploy dev

Normal delivery is build once, then plan/apply dev. Push tested code to main; confirm both images and the dev SSM manifest; dispatch Terraform with the default dev target; dispatch apply; and observe health. Optional staging and production choices remain dormant until their variables and roles are configured. GitHub Environments are not used.

Before approving, confirm workflow run/commit, target account, image digests, plan action counts, replacements, public exposure, IAM changes, state key, and cost impact. After apply, the workflow waits for ECS stability and prints outputs. Verify ALB `/health`, `/api/health`, CRUD, target health, service events, logs, alarm state, and autoscaling registration.

## Incident checks

For an outage, start with ALB target health and ECS service events. Compare desired/running/pending counts, stopped reasons, task definition digest, both container health checks, private routes/NAT, and CloudWatch logs. ALB-generated 5xx suggests routing/target availability; target-generated 5xx points to application failures. Preserve logs and CloudTrail evidence.

Rollback application content by reverting main to known-good application code, publishing a new immutable dev build, generating a new plan, reviewing it, and applying it. Do not edit the ECS service or SSM parameter manually except under a separately documented emergency process; an SSM change alone does not change the running task until Terraform registers/applies a task definition.

## Routine maintenance

Regularly update dependencies and action SHAs through reviewed PRs, scan images, review IAM Access Analyzer/CloudTrail, inspect state versions and locks, audit package visibility, review budgets, validate alarms, and run controlled restore/rollback exercises. Prune neither plan artifacts nor state versions outside policy.

For scaling diagnostics inspect average CPU and scaling activity; remember data is intentionally inconsistent across tasks. For planned deletion use the exact destroy procedure in the setup guide. Local apply, targeted manual resource deletion, mutable tags, `-lock=false`, and console drift are prohibited.

References: [ECS troubleshooting](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/troubleshooting.html), [CloudWatch Logs Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AnalyzingLogData.html), [AWS Well-Architected operations](https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/welcome.html).
