# Remote state and locking

## Model and prerequisites

Terraform state maps configuration addresses to real AWS objects and can contain sensitive values. All accounts use one pre-existing shared S3 bucket, encrypted in transit and at rest, with bucket versioning enabled. The application module does not create its own backend because Terraform must access the backend before it can create resources.

Keys follow `ecs-todo/<account-alias>/<region>/terraform.tfstate`; native S3 locking adds a separate `.tflock` object per key through `use_lockfile=true`. Never use `-lock=false`. CI waits up to ten minutes for legitimate lock holders.

If the bucket is in a shared-services account, its bucket policy must grant each OIDC role `s3:ListBucket` scoped by key prefix plus `s3:GetObject`, `PutObject`, and `DeleteObject` for state and lock objects. Deny non-TLS transport. If SSE-KMS is configured, the role IAM policy and key policy need `kms:Encrypt`, `Decrypt`, `GenerateDataKey`, and `DescribeKey` through S3 for this bucket. The KMS key ARN is optional; S3 encryption remains enabled without it.

## Recovery, security, and verification

An `AccessDenied` can come from role policy, bucket policy, an organisation SCP, permissions boundary, VPC endpoint policy, or KMS key policy. A stale lock should be investigated against active workflow runs before an authorised `terraform force-unlock`; never delete it casually. Versioning allows careful state recovery but does not replace backups or least privilege.

Verify bucket versioning, default encryption, public-access block, bucket policy prefixes, KMS grants, and one distinct state/lock pair per account. Do not print, download, or commit state during troubleshooting.

References: [S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3), [S3 versioning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html), [KMS key policies](https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html).

