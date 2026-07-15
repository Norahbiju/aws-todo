# Container image pipeline

## Sequence

On every PR the pipeline installs deterministic dependencies, lints, tests, builds the production frontend, validates backend import, builds both containers without pushing, and validates Compose. No fork PR receives AWS credentials.

On a main push it repeats validation, authenticates to GHCR with the scoped `GITHUB_TOKEN`, builds `linux/amd64` images with BuildKit cache, pushes `sha-<commit>`, captures registry digests, constructs digest references, assumes the dev OIDC role, verifies the account, and updates the JSON SSM parameter.

Manual promotion accepts two complete immutable references and a target. A strict regex rejects tags and malformed digests. The target's protected environment supplies approval; the job assumes only that account role and changes only that account's parameter. Staging and production reuse identical content instead of rebuilding.

Manifest contract:

```json
{"frontend":"ghcr.io/owner/repo-frontend@sha256:<64 hex>","backend":"ghcr.io/owner/repo-backend@sha256:<64 hex>","git_sha":"<commit>","updated_at":"<UTC>"}
```

## Security, failures, and verification

Package write permission exists only in this workflow; promotion jobs have only contents read and OIDC. Public packages permit anonymous Fargate pulls. A private package requires a secret-backed repository credential design that is intentionally not implemented.

Verify package digest against the workflow summary and SSM JSON before planning. Typical failures are uppercase image names, package visibility, insufficient package permission, wrong AWS account, malformed reference, SSM denial, or unsupported build platform.

References: [GitHub container registry](https://docs.github.com/packages/working-with-a-github-packages-registry/working-with-the-container-registry), [BuildKit cache](https://docs.docker.com/build/cache/backends/gha/), [AWS SSM put-parameter](https://docs.aws.amazon.com/cli/latest/reference/ssm/put-parameter.html).

