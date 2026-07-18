# Security model

## Controls

Network controls place only the ALB in public subnets. Tasks have no public IP, accept 3000/8000 solely from the ALB security group, and reach external services through NAT. No IPv6 route or accidental IPv6 exposure exists. Public HTTP is a demonstration baseline; add ACM-backed HTTPS before handling credentials or private data.

Identity controls use short-lived GitHub OIDC sessions, account-ID checks, provider allowlisting, main-branch restrictions, repository rules, and least-privilege roles. No AWS key, PAT, OIDC token, or Terraform state is committed or transferred between jobs. ECS execution and task roles are distinct and minimal.

Supply-chain controls use deterministic dependency locks, multi-stage non-root images, immutable Git SHAs and registry digests, public anonymous GHCR pulls, explicitly versioned Actions, pinned/checksummed Terraform tooling, saved-plan hashes, and same-run metadata. Run dependency scanning, secret scanning, Dependabot/Renovate, container scanning, and CodeQL in a real repository.

## Governance recommendations

Protect main; require pull-request and CODEOWNERS review; restrict workflow changes; restrict every deployment role's OIDC trust to this repository's main branch; retain GitHub/AWS audit logs; and use SCPs or permission boundaries for additional guardrails. GitHub Environments and environment reviewers are not used. The current deployment workflows are manual/main-only and do not provide PR status checks; add separate non-deployment PR checks before making such checks mandatory in a ruleset.

Repository write access alone must never count as production approval. Reviewers should validate image digests, plan contents, commit, target, and change ticket. Rotate or revoke role trust quickly after repository transfer or rename.

## Limitations and verification

The app has no authentication, database, WAF, TLS, backups, or multi-region recovery and is suitable only for demonstration. Validate security groups, IAM Access Analyzer findings, CloudTrail role sessions, public package visibility, S3 public access block, plan artifact retention, and container vulnerability scans.

References: [AWS shared responsibility](https://aws.amazon.com/compliance/shared-responsibility-model/), [IAM best practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html), [GitHub rulesets](https://docs.github.com/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets).
