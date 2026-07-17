# Container image pipeline

## Sequence

The workflow has no pull-request trigger and does not run separate application test or lint steps. On a main push it authenticates to GHCR with the scoped `GITHUB_TOKEN`, builds the frontend and backend `linux/amd64` images, pushes immutable `sha-<commit>` tags, captures registry digests, constructs digest references, assumes the dev OIDC role, verifies the account, and updates the dev JSON SSM parameter. Any compilation or dependency failure encountered by a Docker build still fails publication.

The workflow reads the dev role ARN, account ID, region, and SSM parameter name from GitHub repository variables. Optional staging and production promotion reads the corresponding role ARN and account-ID variables only when that target is selected. Repository variables are mapped to step environment variables only when a shell command needs them; GitHub Environments are not used.

Optional staging/production promotion remains available through manual dispatch but is dormant during normal dev publication. It reads the current dev manifest and copies the exact immutable references after validating the selected account. Those account variables are needed only when their target is selected. GitHub Environments are not used.

Manifest contract:

```json
{"frontend":"ghcr.io/owner/repo-frontend@sha256:<64 hex>","backend":"ghcr.io/owner/repo-backend@sha256:<64 hex>","git_sha":"<commit>","updated_at":"<UTC>"}
```

Updating the dev SSM manifest does not by itself replace running ECS tasks. Run the manual dev Terraform plan/apply afterward so the exact digests are registered in a new task definition.

## Security, failures, and verification

Package write permission exists only in this workflow. Public packages permit anonymous Fargate pulls. A private package requires a secret-backed repository credential design that is intentionally not implemented.

Verify package digests against the workflow summary and dev SSM JSON before the Terraform apply. Typical failures are uppercase image names, package visibility, insufficient package permission, wrong AWS account, malformed dev manifest, SSM denial, or unsupported build platform.

References: [GitHub container registry](https://docs.github.com/packages/working-with-a-github-packages-registry/working-with-the-container-registry), [BuildKit cache](https://docs.docker.com/build/cache/backends/gha/), [AWS SSM put-parameter](https://docs.aws.amazon.com/cli/latest/reference/ssm/put-parameter.html).
