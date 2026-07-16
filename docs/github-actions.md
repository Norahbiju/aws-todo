# GitHub Actions operating model

## Workflows and authorisation

`container-images.yml` builds and publishes both images on main and updates dev without separate test/lint jobs; optional manual promotion can later copy the current dev manifest to staging or production. `terraform.yml` is workflow-dispatch-only and defaults to dev while retaining optional staging/prod targets. Neither workflow has a pull-request trigger. Missing optional account variables do not affect dev runs; selecting an unconfigured target produces a clear preflight failure.

Authorisation is layered: repository write access permits dispatch, workflow permissions control token scope, branch rules protect reviewed code, AWS OIDC trust restricts tokens to this repository's `main` branch, and IAM policies restrict API actions. GitHub Environments are not used. Only the dev variables are required now; configure staging and production variables and roles before selecting those targets.

Actions are pinned to commit SHAs. Multi-line scripts use strict Bash mode. Required checks do not continue after failure. Deployment concurrency is serialised by target and never cancels an in-progress mutation.

## Trigger and verification boundaries

Docker builds provide the only application build validation during main image publication; separate application lint and test steps are disabled. Terraform validation runs at the beginning of every manual infrastructure operation. Pull requests do not invoke either workflow, so repository rules must not require these workflows as PR status checks unless separate PR-only checks are introduced later.

Verify each job's `permissions`, action SHAs, explicit working directories, main-branch check, account-check step, and summary. Protect `.github/workflows/**` and `infra/**` with CODEOWNERS and repository rulesets.

Common failures include disabled Actions, unavailable hosted runners, missing variables, dispatching from a non-main branch, and OIDC trust mismatch. Use GitHub run logs and audit log without enabling token debug output.

References: [workflow syntax](https://docs.github.com/actions/writing-workflows/workflow-syntax-for-github-actions), [security hardening](https://docs.github.com/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions).
