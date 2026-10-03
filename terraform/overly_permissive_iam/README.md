# Lab: Overly permissive IAM policies

Intentionally vulnerable AWS environment demonstrating how an **overly-permissive role trust
policy** (`Principal: "*"`) lets a near-powerless IAM user escalate into S3 and Secrets Manager.

## What gets deployed

| Resource | Purpose |
|----------|---------|
| IAM user `peachycloud-participant` | Handed to the participant. Only permission: `sts:AssumeRole` on the lab role. |
| IAM role `peachycloud-overly-permissive-role` | **Misconfig:** trust policy allows `Principal: "*"`. Grants S3 read on the flag bucket + scoped Secrets Manager read. |
| S3 bucket `peachycloud-<random>` | Holds `flag.txt`. |
| Secret `peachycloud_sec_flag` | In-scope target secret (readable by the role). |
| Secret `internal_db_password` | Decoy — proves the `peachycloud_sec_*` scoping holds (NOT readable). |
| `participant_credentials.txt` | Generated access keys to hand to the participant (gitignored). |

## Trainer: deploy

> Requires AWS credentials for an **isolated lab account** and OpenTofu/Terraform.

```bash
cd terraform/overly_permissive_iam
tofu init
tofu apply            # review, then approve
```

Hand `participant_credentials.txt` (written next to the TF) to the participant.

Useful outputs:

```bash
tofu output overly_permissive_role_arn
tofu output flag_bucket_name
```

## Trainer: destroy

```bash
tofu destroy
```

Secrets use `recovery_window_in_days = 0`, so they are deleted immediately and the lab can be
re-deployed right away.

## Expected solution

1. Participant has no direct access (`s3 ls` → AccessDenied).
2. `aws sts assume-role` on the `Principal:"*"` role succeeds.
3. With the role's temp creds: list + read the bucket flag, and read `peachycloud_sec_flag`.
4. The decoy `internal_db_password` returns AccessDenied — scoping works.

## ⚠️ Warning

Intentionally vulnerable (`Principal:"*"` trust). Deploy only in an isolated lab account. Never in
production or an account with real data. Always `tofu destroy` after the session.
