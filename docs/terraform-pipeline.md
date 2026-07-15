# Terraform pipeline and exact-plan guarantee

```mermaid
flowchart LR
  PR[Pull request] --> Test[Test + format + validate]
  Test --> Plan[Trusted PR plan\ndev/staging/prod]
  Plan --> Review[Summary + PR comment + review]
  Dispatch[Manual apply/destroy\non main] --> Saved[Generate saved plan]
  Saved --> Render[Render plan + metadata + hash]
  Render --> Artifact[3-day artifact]
  Artifact --> Gate[Protected environment approval]
  Gate --> Download[Checkout same SHA + download]
  Download --> Verify[Verify run, SHA, account, target, action, versions, hash]
  Verify --> Exact[Apply exact binary plan\nno re-plan]
  Exact --> Stable[ECS stability + outputs]
```

## Plan semantics

Terraform detailed exit code 0 means successful/no changes, 2 means successful/changes, and anything else is failure. The scripts temporarily disable shell fail-fast only to capture that value, explicitly accept 0 or 2, and then restore strict mode. A plan needs current SSM image JSON and remote-state access.

Manual plan/apply/destroy generates `plan.tfplan` plus full text and metadata. Artifact names include target, action, commit, and run ID; retention is three days. SHA-256 detects alteration. Metadata binds commit, target, expected account, region, action, workflow run, and tool versions. Plan and apply both run Ubuntu 24.04 with identical pinned versions.

For apply/destroy, a separate environment-gated job checks out the same commit, downloads only the named artifact from the same run, verifies every field and hash, obtains fresh OIDC credentials, reinitialises the same backend, and invokes `terragrunt apply ... plan.tfplan`. It never creates another plan. Destroy requires exact text `DESTROY <target>` and main branch.

## Review, security, and failures

Treat binary plans as sensitive: they can embed values and convey deployment authority within the approved job. Never attach arbitrary PR artifacts or extend retention casually. Review resource replacement, public access, IAM, NAT/ALB cost, task digests, and destroys. Environment reviewers approve the rendered plan and commit—not a future re-plan.

Metadata mismatch, hash mismatch, different commit, expired artifact, state drift after plan, or provider inconsistency intentionally stops deployment. State drift can make exact-plan apply fail; generate a new plan and approval rather than bypassing verification.

References: [saved plans](https://developer.hashicorp.com/terraform/cli/commands/plan), [apply](https://developer.hashicorp.com/terraform/cli/commands/apply), [artifacts](https://docs.github.com/actions/using-workflows/storing-workflow-data-as-artifacts).

