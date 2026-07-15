# AGENTS.md — Complete Todo Application, AWS ECS Infrastructure and CI/CD Implementation

## Your role

Act as a senior software engineer, platform engineer, SRE, DevOps engineer, AWS cloud architect, security engineer and technical documentation writer.

You are working inside an existing repository whose folder structure has already been created manually.

Your responsibility is to implement the complete solution described below. Do not merely provide an architecture proposal, examples or pseudocode. Create the application code, Dockerfiles, Terraform, Terragrunt, GitHub Actions workflows, tests, configuration examples and detailed documentation.

---

# 1. Primary objective

Build a small full-stack Todo application and deploy it to Amazon ECS Fargate using Terraform and Terragrunt.

The solution must include:

1. A Next.js frontend.
2. A Python FastAPI backend.
3. No database.
4. Multi-stage Docker images.
5. Images published to GitHub Container Registry.
6. AWS infrastructure provisioned using one reusable Terraform module.
7. Terragrunt configurations for three separate AWS accounts.
8. Remote Terraform state in a shared S3 bucket with state locking.
9. GitHub Actions authentication to AWS using OIDC.
10. Pull-request Terraform plans.
11. Manually selected plan, apply and destroy operations.
12. Required approval before apply and destroy.
13. Application of the exact saved Terraform plan that was reviewed.
14. Detailed educational documentation explaining every major component.

All AWS infrastructure changes must be executed through GitHub Actions. Do not require users to run `terraform apply`, `terragrunt apply`, `terraform destroy` or `terragrunt destroy` locally.

---

# 2. Repository discovery and folder-structure rules

Before modifying files:

1. Inspect the current repository tree.
2. Inspect existing application, infrastructure, workflow and documentation files.
3. Determine where frontend, backend, Terraform, Terragrunt and documentation files belong within the existing structure.
4. Preserve the manually created structure.
5. Adapt all paths in workflows and configuration files to the actual repository structure.

Do not:

* Replace the existing repository structure with your preferred structure.
* Create duplicate folders such as `frontend-new`, `backend-v2`, `infra-new` or `terraform-final`.
* Move or delete existing files unless doing so is essential.
* Delete existing working functionality.
* Invent paths without first inspecting the repository.
* leave important code as pseudocode or TODO comments.

Where a required directory does not exist, create the smallest appropriate directory within the existing structure.

Use the logical names in this document as concepts. Map them to the repository’s actual folders.

---

# 3. Application architecture

Create a basic Todo application with:

* Next.js frontend.
* TypeScript.
* Python FastAPI backend.
* No database.
* In-memory Todo storage.
* Seeded demonstration Todo records.
* REST API.
* Responsive but simple UI.

Run the frontend and backend as two separate containers inside one ECS Fargate task definition.

Do not run Node.js and Python in the same container.

The Fargate task must contain:

* A frontend container listening on port `3000`.
* A backend container listening on port `8000`.

Use one ECS service containing the two-container task.

Configure the Application Load Balancer as follows:

* Default listener action sends traffic to the frontend target group.
* Requests matching `/api/*` are sent to the backend target group.
* Frontend calls the backend using same-origin relative URLs such as `/api/todos`.
* Do not expose the backend using a separate public hostname.

This architecture intentionally uses two images while satisfying the single-parameter requirement by storing both image URIs in one JSON SSM parameter.

---

# 4. Backend requirements

Create a FastAPI REST API.

Implement at least the following routes:

```text
GET    /api/health
GET    /api/todos
GET    /api/todos/{todo_id}
POST   /api/todos
PATCH  /api/todos/{todo_id}
DELETE /api/todos/{todo_id}
```

A Todo should contain at least:

```text
id
title
description
completed
created_at
```

Backend requirements:

* Use Pydantic request and response models.
* Validate empty or excessively long titles.
* Return appropriate HTTP status codes.
* Return `404` for an unknown Todo.
* Include structured application logging.
* Avoid exposing stack traces to API clients.
* Provide a FastAPI application health endpoint.
* Use an in-memory repository or service abstraction instead of mixing all storage logic directly into route functions.
* Make shared in-memory operations concurrency-safe.
* Add sensible exception handling.
* Add CORS configuration only if necessary for local development.
* Production traffic should use same-origin ALB routing and should not depend on permissive CORS.
* Bind Uvicorn to `0.0.0.0:8000`.
* Do not enable Uvicorn auto-reload in the container.

Add backend tests covering:

* Health endpoint.
* Listing Todos.
* Creating a Todo.
* Updating a Todo.
* Completing a Todo.
* Deleting a Todo.
* Validation failures.
* Missing Todo responses.

Use `pytest`.

Use a lightweight formatter/linter such as Ruff.

Document that in-memory data:

* Resets when a task is restarted.
* Is not shared across multiple ECS tasks.
* Is appropriate only for this demonstration.
* Would need a database or shared state service in a real application.

---

# 5. Frontend requirements

Create a Next.js TypeScript frontend.

The UI must allow a user to:

* View Todos.
* Create a Todo.
* Mark a Todo complete or incomplete.
* Edit a Todo.
* Delete a Todo.
* See loading states.
* See API error messages.
* Retry failed API operations.

Use relative API requests:

```text
/api/todos
```

Do not hardcode the ALB hostname.

Frontend requirements:

* Keep the design simple and professional.
* Make the page usable on desktop and mobile.
* Separate API-client logic from UI components.
* Define proper TypeScript types.
* Avoid using `any`.
* Include an empty-state view.
* Include basic accessibility labels.
* Disable buttons while requests are in progress.
* Use environment variables only where appropriate.
* Default production API base URL to the same origin.
* Add a health endpoint or route suitable for the frontend ALB target-group health check.
* Configure Next.js standalone output for a smaller production container.

Add frontend tests for important UI behavior where practical.

The frontend pipeline must run:

```text
npm ci
npm run lint
npm test
npm run build
```

Adapt commands to the package manager already used by the repository. Do not introduce a second package manager unnecessarily.

---

# 6. Local development

Provide a local Docker Compose configuration that starts:

* Frontend.
* Backend.

The local environment must allow the frontend to communicate with the backend.

Also support running both applications without Docker.

Create example environment files only:

```text
.env.example
```

Never commit real credentials, tokens, role ARNs containing sensitive context or account-specific secrets.

The repository README must include local setup instructions.

---

# 7. Docker requirements

Create separate multi-stage Dockerfiles for the frontend and backend.

## 7.1 Frontend Dockerfile

The Next.js Dockerfile must use at least:

1. Dependency stage.
2. Build stage.
3. Minimal runtime stage.

Requirements:

* Use a supported Node.js LTS image.
* Use deterministic dependency installation.
* Copy only required files.
* Use Next.js standalone output.
* Run as a non-root user.
* Expose port `3000`.
* Set production environment variables.
* Avoid including development dependencies in the final image.
* Include an OCI source label pointing to the repository when possible.
* Include a container health check where reliable.

## 7.2 Backend Dockerfile

The FastAPI Dockerfile must use at least:

1. Python dependency or wheel-building stage.
2. Minimal Python runtime stage.

Requirements:

* Use a supported slim Python image.
* Install dependencies in the builder stage.
* Copy only runtime dependencies into the final image.
* Run as a non-root user.
* Expose port `8000`.
* Start Uvicorn with an exec-form command.
* Do not use the development reload server.
* Prevent Python from writing bytecode.
* Enable unbuffered logs.
* Include a health check against `/api/health` where reliable.
* Do not leave compilers and build tools in the runtime image.

## 7.3 Docker ignore files

Create appropriate `.dockerignore` files.

Exclude:

* Git metadata.
* Node modules.
* Python virtual environments.
* Test caches.
* Terraform caches.
* Local environment files.
* Documentation build output.
* IDE files.
* Secrets.

## 7.4 Image naming

Publish two GHCR images:

```text
ghcr.io/<owner>/<repository>-frontend
ghcr.io/<owner>/<repository>-backend
```

Ensure names are lowercase.

Use immutable tags:

```text
sha-<full-or-short-git-sha>
```

Do not deploy `latest`.

Capture the registry digest produced by each build and store digest-pinned references:

```text
ghcr.io/<owner>/<repository>-frontend@sha256:<digest>
ghcr.io/<owner>/<repository>-backend@sha256:<digest>
```

---

# 8. SSM image-manifest contract

Use one AWS Systems Manager Parameter Store parameter containing both image references.

Recommended parameter name:

```text
/<project-name>/container-images
```

Store it as an SSM `String` containing valid JSON:

```json
{
  "frontend": "ghcr.io/owner/repository-frontend@sha256:...",
  "backend": "ghcr.io/owner/repository-backend@sha256:...",
  "git_sha": "...",
  "updated_at": "..."
}
```

The container-image workflow must create or update this parameter through AWS CLI using GitHub OIDC credentials.

The main Terraform module must read this parameter at plan time using the Terraform AWS provider’s SSM parameter data source.

Terraform must:

1. Read the SSM parameter.
2. Decode the JSON using `jsondecode`.
3. Validate that both `frontend` and `backend` keys exist.
4. Validate that both values are non-empty.
5. Preferably validate that both values contain digest-pinned references.
6. Use those values in the ECS task definition.

Do not:

* Hardcode image URIs in Terraform.
* Pass mutable `latest` tags.
* Manage this image-manifest parameter as a Terraform resource in the main infrastructure module.
* Silently fall back to a placeholder image.

If the parameter is missing, fail with an understandable message explaining that the container-image workflow must be executed first.

The saved Terraform plan must contain the exact image digests that will be applied.

---

# 9. GHCR visibility decision

Use public GHCR packages for the primary implementation so ECS can pull them without a stored registry credential.

Document the one-time GitHub package setting required to make the frontend and backend packages public after their first publication.

Add an explicit warning:

* A private GHCR image cannot be pulled anonymously.
* A private GHCR implementation would require a GitHub read token stored in AWS Secrets Manager and referenced through ECS repository credentials.
* Do not commit a GitHub PAT to Terraform variables, GitHub repository files or task-definition environment variables.

Do not implement the private-registry secret path unless the existing repository clearly requires private packages.

---

# 10. AWS infrastructure requirements

Create one reusable Terraform module that provisions the complete application infrastructure.

It is acceptable and encouraged to split the module into multiple `.tf` files by concern, but all three AWS accounts must use the same module source.

For example:

```text
main.tf
variables.tf
outputs.tf
versions.tf
data.tf
locals.tf
vpc.tf
security-groups.tf
alb.tf
iam.tf
ecs.tf
autoscaling.tf
monitoring.tf
```

Do not create three copies of the Terraform code.

Do not use Terraform workspaces for account separation.

---

# 11. VPC and subnet architecture

Provision:

* One VPC.
* Two public subnets.
* Two private subnets.
* Two availability zones.
* One internet gateway.
* Public route tables.
* Private route tables.
* NAT-based outbound internet access for private ECS tasks.

Use two NAT gateways by default:

* One NAT gateway in each public subnet.
* Each private subnet routes to the NAT gateway in its own availability zone.

This is required because private Fargate tasks must reach public GHCR endpoints while remaining without public IP addresses.

Make CIDR ranges configurable.

Provide safe, non-overlapping example CIDRs for the three accounts, such as:

```text
dev:     10.10.0.0/16
staging: 10.20.0.0/16
prod:    10.30.0.0/16
```

Do not hardcode availability-zone names such as `us-east-1a`, because account-specific AZ mappings can differ. Allow explicit AZ input or select the first two available AZs deterministically.

Tag subnets and resources consistently.

Document that NAT gateways incur ongoing hourly and data-processing costs.

---

# 12. Application Load Balancer

Create an internet-facing Application Load Balancer.

Requirements:

* Place it in both public subnets.
* Use an ALB security group.
* Allow inbound HTTP port `80` from the internet.
* Make HTTPS support optional through a configurable ACM certificate ARN if it can be added without complicating the required HTTP deployment.
* Do not require a custom domain.
* Create separate target groups for frontend and backend.
* Use target type `ip`, which is required for Fargate `awsvpc` tasks.
* Configure health checks.
* Configure sensible deregistration delay.
* Use the frontend target group as the default action.
* Add an ALB listener rule for `/api/*` that forwards to the backend target group.
* Give the API rule an explicit non-conflicting priority.

Recommended health checks:

```text
Frontend: /
Backend:  /api/health
```

The health endpoints must return successful responses without authentication.

Output the ALB DNS name from Terraform.

Also output, where useful:

* ALB ARN.
* ECS cluster name.
* ECS service name.
* VPC ID.
* Public subnet IDs.
* Private subnet IDs.

The required primary output is the ALB DNS name.

---

# 13. Security groups

Create separate security groups for:

1. Application Load Balancer.
2. ECS Fargate tasks.

## ALB security group

Allow:

```text
Inbound TCP 80 from 0.0.0.0/0
```

If IPv6 is enabled, handle it explicitly. Do not accidentally advertise IPv6 without matching subnet and routing configuration.

Allow outbound traffic to the ECS task ports.

## ECS task security group

Allow inbound:

```text
TCP 3000 from the ALB security group only
TCP 8000 from the ALB security group only
```

The source must be the ALB security-group ID, not an internet CIDR.

Do not allow:

```text
0.0.0.0/0 -> 3000
0.0.0.0/0 -> 8000
VPC CIDR -> 3000
VPC CIDR -> 8000
```

unless an existing requirement makes it necessary.

The ECS service must:

* Run only in private subnets.
* Set `assign_public_ip = false`.
* Be reachable from users only through the ALB.
* Have outbound access for GHCR, DNS, logging and AWS service APIs.

Document the complete request path:

```text
Internet
  -> public ALB
  -> ALB security group
  -> private Fargate task ENI
  -> ECS task security group
  -> frontend or backend container
```

---

# 14. ECS cluster and task definition

Create:

* ECS cluster.
* ECS cluster Container Insights configuration.
* CloudWatch log groups.
* ECS task execution IAM role.
* ECS task IAM role.
* Fargate task definition.
* ECS service.

Task-definition requirements:

```text
requires_compatibilities = ["FARGATE"]
network_mode             = "awsvpc"
```

Use a valid Fargate CPU and memory combination.

A reasonable default is:

```text
Task CPU:    512
Task memory: 1024 MiB
```

Allocate sensible resources between the frontend and backend containers.

Both containers must be essential unless there is a justified reason otherwise.

Configure:

* `awslogs` log driver.
* Log-group retention.
* Container names.
* Port mappings.
* Environment variables.
* Container health checks where appropriate.
* Runtime platform consistent with the Docker build platform.

The ECS execution role must contain only the permissions required for ECS startup and CloudWatch logging.

The application task role should have no unnecessary AWS permissions.

Do not give either ECS role administrator permissions.

---

# 15. ECS service

Create one ECS Fargate service.

Requirements:

* Initial desired count: `1`.
* Private subnet placement.
* No public IP.
* ECS task security group.
* Both frontend and backend target-group attachments.
* Deployment circuit breaker with rollback.
* Reasonable health-check grace period.
* Minimum healthy percentage and maximum percentage appropriate for Fargate rolling updates.
* Wait for service stability during Terraform apply where practical.

The service must register:

* Frontend container port `3000` with the frontend target group.
* Backend container port `8000` with the backend target group.

Ensure the ECS service depends on the ALB listener and listener rule where Terraform cannot infer the complete dependency.

---

# 16. ECS autoscaling

Configure ECS Service Auto Scaling using Application Auto Scaling.

Requirements:

```text
Minimum task count: 1
Maximum task count: 4
CPU target:         60%
```

Use target-tracking scaling with:

```text
ECSServiceAverageCPUUtilization
```

Configure reasonable scale-in and scale-out cooldown values.

The scaling target must use:

```text
ecs:service:DesiredCount
```

Document:

* How target-tracking scaling works.
* Why tasks scale together when the task contains both frontend and backend containers.
* Why the in-memory Todo data is not consistent across scaled tasks.
* Why production applications need external persistent state.

---

# 17. CloudWatch monitoring and alarms

Enable ECS Container Insights so the running-task metric is available.

Create at least these alarms:

## Running task count alarm

Alarm when the ECS service’s running task count drops below `1`.

Use:

```text
Namespace: ECS/ContainerInsights
Metric:    RunningTaskCount
Dimensions:
  ClusterName
  ServiceName
Period:    60 seconds
```

Use a statistic and missing-data policy that reliably detects zero running tasks.

## ALB-generated 5xx alarm

Alarm when the ALB returns more than 10 load-balancer-generated 5xx responses within one minute.

Use:

```text
Namespace: AWS/ApplicationELB
Metric:    HTTPCode_ELB_5XX_Count
Statistic: Sum
Period:    60 seconds
Threshold: greater than 10
```

Use the correct `LoadBalancer` metric dimension derived from the ALB ARN suffix.

Also create a separate target-generated 5xx alarm using:

```text
HTTPCode_Target_5XX_Count
```

This additional alarm helps distinguish:

* Errors generated by the ALB itself.
* Errors returned by the application targets.

Allow an optional SNS topic ARN to be supplied for alarm actions. Do not require email subscriptions unless specified.

Document all alarm semantics.

---

# 18. Terraform quality requirements

Use current stable, mutually compatible versions of:

* Terraform.
* AWS Terraform provider.
* Terragrunt.

Pin versions appropriately.

Commit the Terraform provider lock file where appropriate.

Use:

* Input variable descriptions.
* Input validation.
* Typed object and collection variables.
* Locals for naming.
* Consistent resource tags.
* `jsonencode` for ECS container definitions.
* Sensitive output marking where required.
* Lifecycle preconditions or checks for important assumptions.
* `allowed_account_ids` or equivalent protection against deploying to the wrong AWS account.
* Explicit account-ID validation before planning and applying.

Do not use:

* Unpinned provider versions.
* Hardcoded account IDs inside the reusable module.
* Hardcoded image URIs.
* Terraform workspaces.
* Local Terraform state.
* Provisioners unless absolutely unavoidable.
* `local-exec` to deploy resources.
* Null resources for normal infrastructure.
* Shell scripts in place of supported Terraform resources.

Run:

```text
terraform fmt -check -recursive
terraform validate
```

Also configure TFLint if it can be added cleanly.

---

# 19. Terragrunt multi-account architecture

Deploy the same Terraform module to three separate AWS accounts:

```text
dev
staging
prod
```

Map each logical environment to a separate AWS account.

Use the existing folder structure, but logically provide:

```text
infra/
  modules/
    ecs-todo/
  live/
    root.hcl
    dev/
      terragrunt.hcl
    staging/
      terragrunt.hcl
    prod/
      terragrunt.hcl
```

Adapt these paths to the repository.

Use a shared parent Terragrunt configuration for:

* Remote state.
* Common inputs.
* Common tags.
* Region defaults.
* Provider generation if appropriate.
* State-key generation.

Each account configuration must define:

* Account alias.
* Expected AWS account ID.
* AWS region.
* VPC CIDR.
* Public subnet CIDRs.
* Private subnet CIDRs.
* Project name.
* Environment.
* SSM image-manifest parameter name.
* Resource sizing where it differs.

Use one module source from all three account folders.

Do not duplicate Terraform resource definitions between accounts.

---

# 20. Remote Terraform state

Use the existing shared S3 state bucket.

Do not create the shared backend bucket from the same Terraform module that uses it.

Configure:

* S3 remote backend.
* Encryption.
* Unique state key per account.
* Native S3 state locking using `use_lockfile = true`.
* S3 bucket versioning as a documented prerequisite.
* Optional customer-managed KMS key support if the existing state bucket uses one.

Example state-key pattern:

```text
<project>/<account-alias>/<region>/terraform.tfstate
```

State objects and lock objects must never overlap between accounts.

Document the required shared-bucket access for the three existing GitHub OIDC roles.

If the bucket is in a fourth shared-services account, document:

* Required bucket policy.
* Required KMS key policy when using SSE-KMS.
* Cross-account access.
* State-object permissions.
* Lockfile object permissions.

Do not use `-lock=false`.

Use a sensible lock timeout in the pipeline.

---

# 21. Existing AWS IAM roles and GitHub OIDC

The GitHub Actions deployment IAM roles already exist.

Do not create or replace the existing GitHub Actions IAM roles unless the repository already contains an explicit IAM bootstrap layer for them.

Use GitHub OIDC only.

Do not use:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
Long-lived IAM-user credentials
Base64-encoded AWS credentials
Credentials committed to files
```

GitHub Actions jobs that authenticate to AWS must include:

```yaml
permissions:
  id-token: write
  contents: read
```

Use the official AWS credentials action and `role-to-assume`.

Run:

```bash
aws sts get-caller-identity
```

after authentication.

Compare the returned account ID with the expected account ID and fail immediately if they differ.

Create documentation and example policies for:

* GitHub OIDC provider configuration.
* Existing role trust policy.
* `aud` condition for AWS STS.
* `sub` restrictions for the repository.
* Pull-request plan jobs.
* Main-branch manual plan jobs.
* GitHub environment-based apply and destroy jobs.
* Least-privilege permissions needed by the role.
* Shared S3 backend access.
* SSM parameter read and update access.

Do not place real account IDs in committed examples. Use placeholders.

---

# 22. GitHub configuration inputs

Use GitHub repository or organization variables for non-secret values.

Document variables such as:

```text
AWS_ROLE_ARN_DEV
AWS_ROLE_ARN_STAGING
AWS_ROLE_ARN_PROD

AWS_ACCOUNT_ID_DEV
AWS_ACCOUNT_ID_STAGING
AWS_ACCOUNT_ID_PROD

AWS_REGION
TF_STATE_BUCKET
TF_STATE_KMS_KEY_ARN
SSM_IMAGE_PARAMETER_NAME
```

A role ARN is not normally a secret, but keep the configuration consistent with the organization’s policies.

Do not store AWS access keys in GitHub Secrets.

Use GitHub Secrets only when a genuinely secret value is introduced.

---

# 23. Container-image workflow

Create a GitHub Actions workflow dedicated to validating, building and publishing the application images.

Use a suitable name such as:

```text
container-images.yml
```

## Pull-request behavior

On every pull request:

1. Check out code.
2. Install frontend dependencies.
3. Run frontend linting.
4. Run frontend tests.
5. Build the frontend.
6. Install backend dependencies.
7. Run backend linting.
8. Run backend tests.
9. Build both Docker images without pushing.
10. Fail if any step fails.

Do not provide AWS credentials to an untrusted fork pull request.

## Main-branch behavior

On a push to the main branch:

1. Run all application tests.
2. Build both images.
3. Authenticate to GHCR using `GITHUB_TOKEN`.
4. Push immutable SHA tags.
5. Capture the image digests.
6. Construct digest-pinned image references.
7. Update the dev account’s SSM image-manifest parameter through AWS OIDC.
8. Add the published image references to the GitHub Actions job summary.

Required permissions should include only what is necessary, such as:

```yaml
contents: read
packages: write
id-token: write
```

## Manual image promotion

Add `workflow_dispatch` inputs that allow an authorised user to update the image-manifest parameter for:

```text
dev
staging
prod
```

The workflow must accept or resolve a specific immutable frontend and backend digest.

Do not promote a mutable tag.

For staging and production promotions:

* Use protected GitHub environments.
* Require approval where configured.
* Authenticate to the selected AWS account using its existing OIDC role.
* Verify the AWS account ID.
* Update only that account’s SSM parameter.
* Display the promoted digests in the job summary.

Build once and promote immutable digests instead of rebuilding different images for each account.

Use GitHub Actions cache support for Docker BuildKit where appropriate.

---

# 24. Terraform workflow

Create a dedicated GitHub Actions workflow such as:

```text
terraform.yml
```

It must support:

```text
plan
apply
destroy
```

## Triggers

Configure:

```text
pull_request
workflow_dispatch
```

Manual inputs must include:

```text
action:
  plan
  apply
  destroy

target:
  dev
  staging
  prod
```

For destroy, require an additional confirmation input such as:

```text
DESTROY dev
DESTROY staging
DESTROY prod
```

Reject destroy when the confirmation does not exactly match the selected target.

## Pull-request plan

On every trusted pull request:

1. Run Terraform formatting checks.
2. Run Terraform validation.
3. Run Terragrunt validation where supported.
4. Plan the infrastructure for all three account configurations using a matrix.
5. Authenticate separately to each account through OIDC.
6. Verify the active account ID before planning.
7. Read the current image-manifest SSM parameter.
8. Generate a saved Terraform plan.
9. Render a human-readable plan.
10. Publish a concise plan summary in the GitHub job summary.
11. Add or update a pull-request comment containing the plan result.
12. Clearly distinguish:

    * No changes.
    * Changes present.
    * Plan failed.
13. Fail the workflow on any actual Terraform or Terragrunt error.

Handle Terraform detailed exit codes correctly:

```text
0 = success with no changes
2 = success with changes
anything else = failure
```

Do not treat exit code `2` as an error.

For fork pull requests where AWS credentials cannot safely be provided:

* Still run application tests, Docker builds, formatting and validation.
* Clearly state that the AWS-backed plan was not executed due to the untrusted fork security boundary.
* Do not expose AWS credentials to fork code.
* Document that full plans are guaranteed for trusted same-repository pull requests.

## Manual plan

When `action=plan`:

1. Plan only the selected account.
2. Do not apply.
3. Produce a reviewable plan summary.
4. Upload the saved plan as a short-retention artifact if useful.
5. Do not mutate infrastructure.

## Manual apply

When `action=apply`:

1. Require the workflow to run from the main branch.
2. Check out the exact commit being deployed.
3. Authenticate to the selected AWS account using OIDC.
4. Verify the AWS account ID.
5. Initialize the correct remote backend.
6. Generate a saved plan.
7. Generate a human-readable representation of that plan.
8. Write the plan summary to the job summary.
9. Upload the binary plan and integrity metadata as an artifact.
10. Wait for the protected GitHub environment approval.
11. In a separate approved job, check out the same commit.
12. Download the exact saved-plan artifact from the same workflow run.
13. Verify:

    * Workflow run ID.
    * Git commit SHA.
    * Target account.
    * Selected action.
    * Expected account ID.
    * Plan-file SHA-256 hash.
14. Reinitialize the same backend with the same pinned tool versions.
15. Apply the downloaded saved plan directly.
16. Do not run a new plan after approval.
17. Wait for ECS service stability.
18. Print Terraform outputs, including the ALB DNS name.
19. Add the deployment result to the GitHub job summary.

The apply command must apply the saved plan file.

Do not use an unrestricted command equivalent to:

```bash
terraform apply -auto-approve
```

without supplying the reviewed plan file.

## Manual destroy

When `action=destroy`:

1. Require the main branch.
2. Validate the explicit destroy confirmation.
3. Authenticate through OIDC.
4. Verify the selected account.
5. Generate a saved destroy plan using `plan -destroy`.
6. Render the complete destroy plan for review.
7. Upload the destroy plan and integrity metadata.
8. Wait for required GitHub environment approval.
9. Download and verify the exact destroy-plan artifact.
10. Apply that saved destroy plan.
11. Do not run a new destroy plan after approval.
12. Clearly summarize destroyed resources.

Apply and destroy must use protected GitHub environments named consistently with:

```text
dev
staging
prod
```

The repository administrator must configure required reviewers for these environments.

Prefer preventing the initiating user from approving their own deployment where supported.

---

# 25. Plan artifact security

Treat Terraform binary plans as sensitive deployment artifacts.

Implement:

* Short artifact-retention period.
* Unique artifact names containing target, action, commit SHA and run ID.
* SHA-256 checksum.
* Metadata file containing:

  * Commit SHA.
  * Account alias.
  * Expected account ID.
  * Region.
  * Action.
  * Workflow run ID.
  * Terraform version.
  * Terragrunt version.
* Verification before apply.
* Same operating system and architecture for plan and apply jobs.
* Same pinned Terraform and Terragrunt versions.
* Checkout of the same Git commit.
* Concurrency control per target account.
* `cancel-in-progress: false` for deployment operations.

Do not reuse a plan from an unrelated workflow run.

Do not download and apply arbitrary pull-request artifacts from untrusted code.

The exact-plan guarantee applies to the manually generated plan and its approved apply or destroy job within the same workflow run.

---

# 26. Workflow safety requirements

All workflows must:

* Use minimal permissions.
* Use `set -euo pipefail` in multi-line shell scripts.
* Avoid `continue-on-error` for required validation.
* Fail on Terraform errors.
* Fail on Terragrunt errors.
* Fail on test errors.
* Fail on Docker build errors.
* Validate inputs.
* Avoid printing credentials.
* Avoid printing full OIDC tokens.
* Avoid storing credentials in artifacts.
* Avoid passing credentials between jobs.
* Use fresh OIDC authentication in each AWS job.
* Use immutable or securely pinned third-party GitHub Actions.
* Use concurrency groups to prevent overlapping writes to the same state.
* Use explicit working directories.
* Avoid broad `write-all` permissions.

Apply and destroy jobs must be serialised per target account.

---

# 27. Authorisation model

Document that authorised deployment users are controlled through:

1. Repository write access.
2. GitHub Actions workflow permissions.
3. Protected GitHub environments.
4. Required environment reviewers.
5. Branch protection or repository rulesets.
6. AWS IAM OIDC trust policy.
7. AWS IAM permissions attached to the existing role.

Explain that GitHub repository write access alone should not be treated as sufficient production approval.

Document recommended settings:

* Protect the main branch.
* Require pull-request review.
* Require successful application and Terraform checks.
* Require CODEOWNERS review for infrastructure and workflow changes.
* Restrict modifications to `.github/workflows`.
* Configure required reviewers for staging and production.
* Prevent self-review where available.
* Restrict production OIDC trust to the production GitHub environment.

---

# 28. Documentation deliverables

Create comprehensive learning-oriented documentation.

At minimum provide:

```text
README.md
docs/application.md
docs/docker.md
docs/architecture.md
docs/aws-networking.md
docs/ecs-fargate.md
docs/alb-and-security-groups.md
docs/terraform.md
docs/terragrunt-multi-account.md
docs/remote-state.md
docs/github-actions.md
docs/github-oidc-aws.md
docs/container-image-pipeline.md
docs/terraform-pipeline.md
docs/autoscaling.md
docs/cloudwatch-monitoring.md
docs/security.md
docs/cost-considerations.md
docs/setup-guide.md
docs/operations.md
docs/troubleshooting.md
```

Adapt paths to the existing documentation structure.

Each document must explain:

* What the component is.
* Why it is used.
* How it works internally.
* How it connects to the rest of the architecture.
* Important configuration values.
* Security considerations.
* Common failure modes.
* How to verify it.
* Relevant AWS, HashiCorp, Terragrunt, Docker and GitHub terminology.
* Links or references to official documentation.

Avoid copying large sections from external documentation. Explain concepts in original language.

---

# 29. Required architecture diagrams

Use Mermaid diagrams in the documentation.

Create at least:

## Runtime architecture

```text
User
 -> Internet-facing ALB
 -> frontend target group
 -> Next.js container

User /api/*
 -> Internet-facing ALB
 -> backend target group
 -> FastAPI container
```

Show:

* Public subnets.
* Private subnets.
* Availability zones.
* NAT gateways.
* ECS task ENIs.
* Security groups.
* CloudWatch Logs.
* SSM parameter.
* GHCR.

## GitHub OIDC sequence

Show:

```text
GitHub Actions
 -> GitHub OIDC token
 -> AWS STS AssumeRoleWithWebIdentity
 -> temporary AWS credentials
 -> Terraform/Terragrunt
 -> AWS APIs
```

## Pipeline sequence

Show:

```text
PR
 -> test
 -> validate
 -> plan
 -> review

Manual apply
 -> plan
 -> publish plan summary
 -> environment approval
 -> download exact plan
 -> verify hash and metadata
 -> apply exact plan
```

## Multi-account Terragrunt architecture

Show:

```text
One Terraform module
 -> dev account configuration
 -> staging account configuration
 -> prod account configuration
```

Show separate state keys in the shared state bucket.

---

# 30. Setup documentation

Create a complete setup guide covering:

1. Required software for local validation.
2. GitHub repository settings.
3. GitHub Actions permissions.
4. GitHub package permissions.
5. Making GHCR packages public.
6. Required repository variables.
7. Required GitHub environments.
8. Required reviewers.
9. Existing AWS OIDC roles.
10. OIDC trust-policy examples.
11. IAM permission-policy examples.
12. Shared S3 state bucket configuration.
13. S3 versioning.
14. S3 state locking.
15. Cross-account bucket policy.
16. KMS key policy if applicable.
17. First container-image publication.
18. First SSM parameter creation.
19. First dev Terraform plan.
20. First approved dev apply.
21. Promoting the same image digests to staging and production.
22. Safely destroying an environment.

Do not instruct the user to bypass the pipeline.

Local commands may be documented for:

* Formatting.
* Validation.
* Tests.
* Docker builds.
* Read-only inspection.

Local apply and destroy must be marked as prohibited by the project’s operating model.

---

# 31. Cost documentation

Document the main cost-generating resources:

* Two NAT gateways per account.
* NAT gateway data processing.
* Application Load Balancer.
* Fargate task CPU and memory.
* CloudWatch Logs.
* Container Insights.
* CloudWatch alarms.
* S3 state storage.
* Cross-account or internet data transfer where applicable.

Explain that three AWS accounts multiply baseline infrastructure costs.

Include a clearly marked cost-optimised alternative using one NAT gateway per non-production VPC, but do not make that the secure/high-availability default unless configured through an explicit variable.

Do not silently switch production to one NAT gateway.

---

# 32. Troubleshooting documentation

Include troubleshooting for at least:

* GitHub OIDC `Not authorized to perform sts:AssumeRoleWithWebIdentity`.
* OIDC `sub` condition mismatch.
* Wrong AWS account assumed.
* Shared S3 bucket `AccessDenied`.
* KMS decrypt or encrypt failure.
* Terraform state lock failure.
* Missing SSM image parameter.
* Invalid JSON in the SSM image parameter.
* GHCR package still private.
* ECS `CannotPullContainerError`.
* Private subnet without a working NAT route.
* ECS task failing health checks.
* ALB target remaining unhealthy.
* Incorrect target-group port.
* ECS service unable to register both containers.
* Frontend returning 404 for `/api/*`.
* FastAPI route-prefix mismatch.
* CloudWatch logs not appearing.
* Running task alarm showing insufficient data.
* Container Insights not enabled.
* Terraform plan exit code `2` incorrectly treated as failure.
* Saved-plan artifact mismatch.
* Plan generated from a different commit.
* GitHub environment approval not appearing.
* Autoscaling not triggering immediately.
* In-memory Todo inconsistency after scaling.

---

# 33. Validation and acceptance testing

After implementation, run all available validations that do not require unavailable external credentials.

At minimum run:

## Backend

```text
lint
tests
application import/startup validation
```

## Frontend

```text
dependency installation
lint
tests
production build
```

## Containers

```text
frontend Docker build
backend Docker build
Docker Compose configuration validation
```

## Terraform

```text
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

Run validation against the reusable module.

## Terragrunt

Validate the Terragrunt configuration syntax and module paths without applying infrastructure.

## GitHub Actions

Validate workflow YAML structure using an available workflow linter where possible.

Do not claim that AWS resources were deployed unless an actual authenticated deployment was performed.

---

# 34. Infrastructure acceptance criteria

The completed solution must satisfy all of the following:

* Exactly one reusable Terraform infrastructure module is used by all three accounts.
* Three Terragrunt account configurations exist.
* Each configuration points to a separate AWS account.
* State is isolated by unique S3 keys.
* S3 native state locking is enabled.
* No local state is used.
* No Terraform workspaces are used.
* A VPC is created.
* Two public subnets exist across two AZs.
* Two private subnets exist across two AZs.
* The ALB is internet-facing and placed in public subnets.
* Fargate tasks are placed only in private subnets.
* Fargate tasks have no public IP.
* Private subnets have NAT egress.
* ECS tasks can pull public GHCR images.
* One ECS cluster exists.
* One ECS service runs a two-container task.
* Frontend and backend use separate multi-stage images.
* The image URIs are read from one SSM parameter during Terraform planning.
* Image references are pinned by digest.
* `/api/*` routes to FastAPI.
* Other paths route to Next.js.
* ECS ingress is allowed only from the ALB security group.
* Service autoscaling minimum is 1.
* Service autoscaling maximum is 4.
* CPU target is 60%.
* A running-task-count alarm exists.
* An ALB-generated 5xx alarm exists.
* A target-generated 5xx alarm exists.
* CloudWatch application logs exist.
* Terraform outputs the ALB DNS name.
* GitHub Actions uses OIDC.
* No AWS access keys are stored.
* Pull requests produce reviewable plans.
* Apply and destroy require approval.
* Apply uses the exact reviewed saved plan.
* Destroy uses the exact reviewed saved destroy plan.
* Workflow failures propagate correctly.
* Documentation explains the complete system.

---

# 35. Final response after implementation

When all implementation work is complete, provide:

1. A concise summary of what was created.
2. The final relevant repository tree.
3. A list of files created.
4. A list of files modified.
5. Tests and validations executed.
6. Exact validation results.
7. Any validation that could not be executed and why.
8. GitHub repository variables that must be configured.
9. GitHub environments that must be configured.
10. AWS prerequisites that must already exist.
11. GHCR package-visibility steps.
12. The first pipeline execution sequence.
13. Remaining placeholders that the user must replace.
14. Important security and cost warnings.

Do not hide failures.

Do not state that something works unless it was validated.

Do not finish with only an implementation plan. Complete the implementation.
