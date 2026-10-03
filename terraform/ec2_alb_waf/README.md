# Lab: EC2 & ALB security + Attacking AWS WAF

One deployment that backs two training labs:

- **EC2 & ALB security** — vulnerable PHP app on EC2 behind an ALB, security group open to
  `0.0.0.0/0`, exploited via LFI / command injection to read files, steal the instance's AWS
  credentials, and grab the flag.
- **Attacking AWS WAF** — an AWS WAF Web ACL (Common / Linux / PHP managed rule sets) on the ALB;
  block naive requests, bypass with a realistic User-Agent, then analyse WAF logs in Athena.

## What gets deployed

| Module | Resource |
|--------|----------|
| `vpc` | VPC + IGW + 2 public subnets + routing |
| `security-group` | SG allowing inbound `0.0.0.0/0:80` |
| `ec2` | EC2 running the vulnerable app; flag written to `/opt/flag.txt` at deploy |
| `load-balancer` | Application Load Balancer in front of EC2 |
| `waf` | WAFv2 Web ACL (Common/Linux/PHP managed rules) associated to the ALB |
| `waf_logging` | Firehose → S3 for WAF logs + Athena output bucket |

## Trainer: deploy

Requires AWS credentials for an isolated lab account and OpenTofu/Terraform. Region defaults to
`us-west-2`.

```bash
cd terraform/ec2_alb_waf
bash deploy.sh
```

`deploy.sh` generates a random flag, writes it to the instance, and saves outputs to
`terraform_waf_output.json`. Give participants the `load_balancer_dns`.

## Trainer: destroy

```bash
bash destroy.sh
```

If destroy errors on a non-empty S3 bucket, empty it in the console and re-run.

## Participant walkthrough

See the training docs:

- EC2 & ALB security (LFI → creds → flag)
- Attacking AWS WAF (403 → User-Agent bypass → flag → Athena log analysis)
