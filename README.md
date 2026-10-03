# aws-security-labs

Hands-on AWS cloud-security lab scenarios for the Practical Security training. Each lab has two
parts:

1. **Trainer deployment** — Terraform that stands up the intentionally vulnerable AWS infrastructure.
   The trainer deploys it into their own lab account, then hands access to participants.
2. **Participant steps** — the run + exploit walkthrough the participant follows against the
   deployed environment.

> Credentials are assumed to be generated and configured by the trainer's deployment. Lab docs
> never contain real secrets.

## Layout

```
terraform/            # per-lab Terraform (added scenario by scenario)
```

## Planned labs

- Basics of IAM policies
- Overly permissive IAM policies
- Attacking S3 buckets
- Attacking AWS WAF
- EC2 & ALB security
- AWS misconfiguration challenges

> Scenarios and their Terraform are added one by one. This repo starts as the skeleton.

## ⚠️ Warning

These environments are **intentionally vulnerable**. Deploy only in an isolated lab AWS account,
never in production or an account holding real data. Destroy (`terraform destroy`) after each session.
