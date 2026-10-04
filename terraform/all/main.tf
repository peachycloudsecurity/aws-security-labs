###############################################################################
# One-shot deployment of ALL AWS security labs.
#   tofu apply   -> IAM (overly-permissive), S3 (public buckets), EC2/ALB/WAF
#   tofu destroy -> tears everything down
#
# A single shared participant + trainer user is created here and used across the
# labs (both have identical, minimal permissions so a trainer can demo the exact
# same steps participants run).
###############################################################################

data "aws_region" "current" {}

resource "random_string" "suffix" {
  length  = 8
  lower   = true
  upper   = false
  numeric = true
  special = false
}

# ---- Lab modules ----
module "overly" {
  source = "./modules/overly"
  suffix = random_string.suffix.result
}

# The S3 lab is intentionally about PUBLIC buckets. If the lab account has S3
# Block Public Access enabled (default on newer accounts), public bucket policies
# are refused. Disable it account-wide so the lab can create its public buckets.
resource "aws_s3_account_public_access_block" "this" {
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Disabling account Block Public Access is eventually consistent; wait for it to
# propagate before the S3 module creates public bucket policies (avoids a
# BlockPublicPolicy AccessDenied race on the first apply).
resource "time_sleep" "bpa_propagate" {
  depends_on      = [aws_s3_account_public_access_block.this]
  create_duration = "20s"
}

module "s3" {
  source     = "./modules/s3"
  suffix     = random_string.suffix.result
  depends_on = [time_sleep.bpa_propagate]
}

module "ec2_alb_waf" {
  source    = "./modules/ec2_alb_waf"
  providers = { aws = aws.usw2 }
}

# ---- Shared users (participant + trainer), identical minimal permissions ----
locals {
  lab_users = toset(["participant", "trainer"])
}

resource "aws_iam_user" "lab" {
  for_each      = local.lab_users
  name          = "peachycloud-${each.key}-${random_string.suffix.result}"
  force_destroy = true
}

resource "aws_iam_access_key" "lab" {
  for_each = local.lab_users
  user     = aws_iam_user.lab[each.key].name
}

resource "aws_iam_user_policy" "lab" {
  for_each = local.lab_users
  name     = "lab-access"
  user     = aws_iam_user.lab[each.key].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AssumeLabRole"
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = module.overly.role_arn
      },
      {
        Sid    = "ReadIAM"
        Effect = "Allow"
        Action = [
          "iam:GetRole", "iam:ListRoles",
          "iam:ListRolePolicies", "iam:GetRolePolicy", "iam:ListAttachedRolePolicies",
          "iam:ListUsers", "iam:GetUser",
          "iam:ListUserPolicies", "iam:GetUserPolicy", "iam:ListAttachedUserPolicies",
          "iam:ListPolicies", "iam:GetPolicy", "iam:GetPolicyVersion"
        ]
        Resource = "*"
      }
    ]
  })
}

# ---- Generated files ----
resource "local_file" "lab_env" {
  filename        = "${path.module}/lab_env.sh"
  file_permission = "0644"
  content         = <<-EOT
    # source this: `source lab_env.sh`
    # IAM + S3 labs: us-east-1   |   EC2/ALB/WAF lab: us-west-2
    export AWS_DEFAULT_REGION=us-east-1

    # Overly-permissive IAM lab
    export ROLE_ARN=${module.overly.role_arn}
    export ROLE_NAME=${module.overly.role_name}
    export FLAG_BUCKET=${module.overly.flag_bucket}
    export IN_SCOPE_SECRET=${module.overly.in_scope_secret}
    export DECOY_SECRET=${module.overly.decoy_secret}

    # Attacking S3 lab
    export LISTABLE_BUCKET=${module.s3.listable_bucket}
    export WRITABLE_BUCKET=${module.s3.writable_bucket}

    # EC2 & ALB / WAF lab (us-west-2)
    export LB_DNS=${module.ec2_alb_waf.load_balancer_dns}
  EOT
}

resource "local_file" "participant_credentials" {
  filename        = "${path.module}/participant_credentials.txt"
  file_permission = "0600"
  content         = <<-EOT
    ================================================================
     AWS Security Labs - Participant credentials  (keep private)
    ================================================================

    This IAM user has no direct access to data. Find what it can do.

    1) Configure an AWS CLI profile named "participant":
         aws configure --profile participant
           AWS Access Key ID     = ${aws_iam_access_key.lab["participant"].id}
           AWS Secret Access Key = ${aws_iam_access_key.lab["participant"].secret}
           Default region        = us-east-1
           Default output        = json

    2) Load lab resource names:
         source lab_env.sh

    Start here:
      aws sts get-caller-identity --profile participant
    ================================================================
  EOT
}

resource "local_file" "trainer_credentials" {
  filename        = "${path.module}/trainer_credentials.txt"
  file_permission = "0600"
  content         = <<-EOT
    ================================================================
     AWS Security Labs - TRAINER credentials (same user type as participants)
    ================================================================

    1) Configure a profile named "trainer":
         aws configure --profile trainer
           AWS Access Key ID     = ${aws_iam_access_key.lab["trainer"].id}
           AWS Secret Access Key = ${aws_iam_access_key.lab["trainer"].secret}
           Default region        = us-east-1
           Default output        = json

    2) source lab_env.sh  then run the same steps with --profile trainer.
    ================================================================
  EOT
}
