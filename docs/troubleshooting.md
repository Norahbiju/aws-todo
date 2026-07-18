# Troubleshooting

Use the symptom table from top to bottom. Keep investigations read-only until the cause is understood; never expose credentials, state, OIDC tokens, or private plan contents.

| Symptom | Likely cause and safe checks |
|---|---|
| `Not authorized to perform sts:AssumeRoleWithWebIdentity` | Provider/role ARN, `aud`, or `sub` trust mismatch. Confirm the run is on main and compare the exact repository/ref trust conditions with the CloudTrail denial. |
| OIDC `sub` mismatch | All authenticated jobs use `ref:refs/heads/main`; no environment or PR subject is used. Names and repository owner casing must match policy. |
| Wrong AWS account assumed | Variable maps to the wrong role or role trust crosses accounts. The workflow stops after `sts get-caller-identity`; correct variables/trust, never bypass the check. |
| Shared S3 `AccessDenied` | Inspect role, bucket policy, SCP, permissions boundary, object prefix, and TLS condition. Confirm the environment-specific state and `.tflock` ARNs. |
| Terraform state lock failure | Another run may own the lock. Check Actions concurrency and lock metadata; wait or use an authorised force-unlock only after proving no active writer. Never use `-lock=false`. |
| Missing SSM image parameter | Run main image publication for dev. Confirm the parameter name and region. Terraform intentionally has no fallback. |
| Invalid SSM JSON | Read the value without logging it publicly; validate with `jq`. It needs `frontend` and `backend` digest strings. Re-run the image workflow. |
| GHCR package still private | Change both package visibilities to Public after initial publication, then confirm anonymous manifest access. Do not add a PAT to the task. |
| ECS `CannotPullContainerError` | Check exact digest existence, public visibility, platform, DNS, private default route, NAT availability/EIP, and stopped-task detail. |
| Private subnet has no working NAT | Confirm route-table association, `0.0.0.0/0` target, NAT `Available`, NAT public subnet route to IGW, and network ACLs. |
| ECS task fails container health | The backend retains a Python in-container probe; test its exact command, port, startup time, bind address, and logs. Frontend health is determined by the ALB `/health` target check, avoiding a duplicate in-container probe while still validating the full network path. |
| ALB target remains unhealthy | Compare health path, matcher, target port, task/container mapping, ALB-to-ECS SG rules, grace period, and `describe-target-health` reason. |
| Incorrect target-group port | Frontend is 3000 and backend 8000 in task port mapping, service attachment, SG rule, and target group. Fix code and apply a reviewed plan. |
| Service cannot register both containers | Both names and ports must match task definition exactly; inspect ECS service events and ensure both are essential/healthy. |
| Frontend returns 404 for `/api/*` | API listener rule may be absent/lower priority or request path lacks `/api`. Verify rule priority 100 and ALB DNS request. |
| FastAPI route-prefix mismatch | Routes and health must begin `/api`; compare OpenAPI at `/api/docs` and ALB rule. |
| CloudWatch logs do not appear | Check log group/region, `awslogs` options, execution role `CreateLogStream`/`PutLogEvents`, and task initialization errors. |
| Running-task alarm is insufficient data | Confirm Container Insights cluster setting, exact cluster/service dimensions, region, and initial metric delay. Missing data later is configured as breaching. |
| Container Insights not enabled | Confirm ECS cluster setting value `enabled`; apply the module change and wait for new metrics. |
| Terraform plan exit code 2 treated as failure | Required capture block must temporarily disable fail-fast, accept 0 and 2, then re-enable it. This workflow implements that sequence. |
| Saved-plan artifact mismatch | Commit, target, account, region, action, run ID, tool versions, or SHA-256 differs. Stop; never override. Generate a new plan. |
| Plan is from a different commit | The metadata and checkout verification must fail. Dispatch from the intended main commit and generate a new plan. |
| Manual Terraform operation stops before authentication | All Terraform operations must be dispatched from `main`. Re-run the workflow using the main branch. |
| Autoscaling does not trigger immediately | CPU must be sustained; metric and cooldown delays apply. Check target registration, max capacity, scaling activities, quotas, subnet IPs, and task health. |
| Todos differ after scaling | Expected for process-local memory. Reduce to one task only for demonstration consistency or implement external persistent state for production. |
| Apply reports state changed since plan | Infrastructure or state drifted after planning. Generate and review a fresh plan; never re-plan inside the exact-plan deploy job. |
| Destroy fails on production ALB | Deletion protection is enabled. Submit a reviewed normal change disabling it, apply that exact plan, then create a new destroy plan. |

Useful read-only commands include `aws sts get-caller-identity`, `aws ecs describe-services`, `aws ecs describe-tasks`, `aws elbv2 describe-target-health`, `aws logs tail`, `aws ec2 describe-route-tables`, and `terragrunt output`. Run them only with authorised credentials and avoid copying sensitive output into public issues.

References: [ECS stopped-task errors](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/stopped-task-error-codes.html), [OIDC troubleshooting](https://docs.github.com/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect), [Terraform state locking](https://developer.hashicorp.com/terraform/language/state/locking).
