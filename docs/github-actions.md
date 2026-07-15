# GitHub Actions operating model

## Workflows and authorisation

`container-images.yml` validates every pull request, publishes on main, updates dev, and promotes immutable digests manually. `terraform.yml` validates IaC, plans trusted pull requests across all accounts, and provides manual plan/apply/destroy operations. AWS jobs request fresh OIDC credentials; credentials are never passed through artifacts.

Authorisation is layered: repository write access permits dispatch, workflow permissions control token scope, branch rules protect reviewed code, GitHub environments hold required reviewers, AWS OIDC trust restricts token subjects, and IAM policies restrict API actions. Write access alone is not production approval. Configure required reviewers for staging/prod, prevent self-review where available, and restrict production role trust to `repo:OWNER/REPOSITORY:environment:prod`.

Actions are pinned to commit SHAs. Multi-line scripts use strict Bash mode. Required checks do not continue after failure. Deployment concurrency is serialised by target and never cancels an in-progress mutation.

## Forks and verification

Fork pull requests run application tests, Docker builds, formatting, and provider-schema validation, but receive no AWS token. Full AWS plans are guaranteed only for trusted same-repository pull requests. This boundary prevents unreviewed fork code from stealing temporary credentials.

Verify each job's `permissions`, action SHAs, explicit working directories, account-check step, environment gate, and summary. Protect `.github/workflows/**` and `infra/**` with CODEOWNERS and repository rulesets.

Common failures include disabled Actions, unavailable hosted runners, missing variables, environment approval not appearing, and OIDC trust mismatch. Use GitHub run logs and audit log without enabling token debug output.

References: [workflow syntax](https://docs.github.com/actions/writing-workflows/workflow-syntax-for-github-actions), [security hardening](https://docs.github.com/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions), [environments](https://docs.github.com/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment).

