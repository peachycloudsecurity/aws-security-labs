# Lab: Attacking S3 buckets

Two separate **intentionally public** S3 buckets. The participant uses the **same no-permission IAM
user** as the first lab — proving that when a bucket is public, IAM identity permissions don't matter.

## What gets deployed

| Resource | Purpose |
|----------|---------|
| `peachycloud-listable-<rand>` | World-**listable** + readable (`Principal:"*"`, `s3:ListBucket`+`s3:GetObject`). Holds `flag.txt` + decoys. |
| `peachycloud-writable-<rand>` | World-**writable** + readable (`Principal:"*"`, `s3:PutObject`+`s3:GetObject`, no public list). Holds `flag.txt` + `README.txt`. |
| IAM user `peachycloud-participant` | Zero permissions. Access keys written to `participant_credentials.txt`. |

> Flags: `FLAG{s3_public_listable_bucket}` and `FLAG{s3_public_writable_bucket}`.

## Reuse the first lab's credentials

If the **Overly permissive IAM** lab is already deployed, don't create a second participant user —
reuse those credentials:

```bash
tofu apply -var create_participant_user=false
```

## Trainer: deploy

```bash
cd terraform/attacking_s3
tofu init
tofu apply
```

Hand `participant_credentials.txt` to the participant. Useful outputs:

```bash
tofu output listable_bucket
tofu output writable_bucket
```

## Expected solution

1. With the no-perm creds (or even anonymously), **list** `peachycloud-listable-*` and download `flag.txt`.
2. **Upload** a file to `peachycloud-writable-*` (public write) and read `flag.txt`.
3. Note the writable bucket cannot be *listed* — only put/get are public, so you must know the key.

## Trainer: destroy

```bash
tofu destroy
```

## ⚠️ Warning

Creates PUBLIC buckets, one **world-writable**. Anyone on the internet can read/write them while they
exist. Deploy only in an isolated lab account and `tofu destroy` as soon as the session ends.
