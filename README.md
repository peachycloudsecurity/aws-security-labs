# aws-security-labs

Hands-on AWS cloud-security lab scenarios for the Practical Security training. Each lab has two
parts:

1. **Trainer deployment** — Terraform that stands up the intentionally vulnerable AWS infrastructure.
2. **Participant steps** — the run + exploit walkthrough the participant follows.

All labs deploy together from a single root — **one `tofu apply`**, one `tofu destroy`:

```
terraform/all/
├── main.tf        # shared participant + trainer user, lab_env.sh + credential files
├── providers.tf   # us-east-1 (IAM/S3) + us-west-2 (EC2/ALB/WAF)
├── outputs.tf
└── modules/
    ├── overly/        # Overly permissive IAM (Principal:* role -> S3 + scoped Secrets)
    ├── s3/            # Public listable + writable buckets
    └── ec2_alb_waf/   # Vulnerable EC2 behind ALB + AWS WAF (bypass + Athena logs)
```

## Deploy / destroy

```bash
cd terraform/all
tofu init
tofu apply      # deploys ALL labs
# ... run the labs ...
tofu destroy    # tears everything down
```

A random suffix makes every resource name unique, so re-deploys never collide. Credentials are
written to `participant_credentials.txt` / `trainer_credentials.txt`, and resource names to
`lab_env.sh` (all gitignored).

> Intentionally vulnerable. Deploy only in an isolated lab AWS account; destroy after each session.
