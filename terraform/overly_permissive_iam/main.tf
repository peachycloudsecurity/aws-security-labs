###############################################################################
# Lab: Overly permissive IAM policies
#
# Scenario deployed by the TRAINER:
#   - A near-powerless IAM user ("participant") whose ONLY permission is
#     sts:AssumeRole. Its access keys are written to participant_credentials.txt
#     and handed to the participant.
#   - An IAM role whose TRUST POLICY allows Principal "*" (anyone can assume it).
#     This is the overly-permissive misconfiguration the lab teaches.
#   - The role can list+read an S3 bucket (peachycloud-<random>) holding a flag.
#   - The role can read Secrets Manager secrets, but ONLY those whose name
#     starts with "peachycloud_sec_" (resource-scoped). A decoy secret proves
#     the scoping holds.
#
# The participant assumes the wide-open role and escalates from "no access" to
# reading the bucket flag and the scoped secret.
###############################################################################

terraform {
  required_version = ">= 1.3"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.0" }
    local  = { source = "hashicorp/local", version = "~> 2.0" }
  }
}

provider "aws" {
  default_tags {
    tags = {
      Project = "aws-security-labs"
      Lab     = "overly_permissive_iam"
      Managed = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "random_string" "suffix" {
  length  = 8
  lower   = true
  upper   = false
  numeric = true
  special = false
}

locals {
  bucket_name = "peachycloud-${random_string.suffix.result}"
  region      = data.aws_region.current.name
  account_id  = data.aws_caller_identity.current.account_id
}

###############################################################################
# 1. Participant user — minimal: can ONLY assume the lab role.
###############################################################################

resource "aws_iam_user" "participant" {
  name          = "peachycloud-participant"
  force_destroy = true
}

resource "aws_iam_access_key" "participant" {
  user = aws_iam_user.participant.name
}

# The only thing this user can do is call sts:AssumeRole on the lab role.
resource "aws_iam_user_policy" "participant_assume" {
  name = "allow-assume-lab-role"
  user = aws_iam_user.participant.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "AssumeLabRole"
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = aws_iam_role.overly_permissive.arn
    }]
  })
}

###############################################################################
# 2. The overly-permissive role — trust policy allows Principal "*".
###############################################################################

resource "aws_iam_role" "overly_permissive" {
  name = "peachycloud-overly-permissive-role"

  # !!! MISCONFIGURATION: any principal can assume this role.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowAnyPrincipal"
      Effect    = "Allow"
      Principal = { AWS = "*" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "overly_permissive" {
  name = "lab-access"
  role = aws_iam_role.overly_permissive.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListTheLabBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.flag.arn
      },
      {
        Sid      = "ReadLabBucketObjects"
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.flag.arn}/*"
      },
      {
        # Discovery only: can see secret names (incl. the decoy) but...
        Sid      = "ListSecrets"
        Effect   = "Allow"
        Action   = "secretsmanager:ListSecrets"
        Resource = "*"
      },
      {
        # ...can only READ secrets named peachycloud_sec_*
        Sid      = "ReadScopedSecrets"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        Resource = "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:peachycloud_sec_*"
      }
    ]
  })
}

###############################################################################
# 3. S3 bucket + flag object.
###############################################################################

resource "aws_s3_bucket" "flag" {
  bucket        = local.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "flag" {
  bucket                  = aws_s3_bucket.flag.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "flag" {
  bucket  = aws_s3_bucket.flag.id
  key     = "flag.txt"
  content = "FLAG{s3_bucket_read_via_overly_permissive_role}\n"
}

###############################################################################
# 4. Secrets Manager — one in-scope secret (the target) + one decoy.
###############################################################################

resource "aws_secretsmanager_secret" "in_scope" {
  name                    = "peachycloud_sec_flag"
  recovery_window_in_days = 0 # allow immediate re-create in labs
}

resource "aws_secretsmanager_secret_version" "in_scope" {
  secret_id     = aws_secretsmanager_secret.in_scope.id
  secret_string = "FLAG{secrets_manager_scoped_read_peachycloud_sec}"
}

# Decoy: NOT named peachycloud_sec_* -> role must NOT be able to read it.
resource "aws_secretsmanager_secret" "decoy" {
  name                    = "internal_db_password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "decoy" {
  secret_id     = aws_secretsmanager_secret.decoy.id
  secret_string = "SHOULD-NOT-BE-READABLE-super-secret-db-password"
}

###############################################################################
# 5. Credentials file handed to the participant.
###############################################################################

resource "local_file" "participant_credentials" {
  filename        = "${path.module}/participant_credentials.txt"
  file_permission = "0600"
  content         = <<-EOT
    ================================================================
     AWS Security Lab - Overly permissive IAM policies
     Participant credentials  (keep these private)
    ================================================================

    AWS_ACCESS_KEY_ID     = ${aws_iam_access_key.participant.id}
    AWS_SECRET_ACCESS_KEY = ${aws_iam_access_key.participant.secret}
    AWS_DEFAULT_REGION    = ${local.region}

    This IAM user has NO direct permissions. Your job is to find what,
    if anything, it can do - and how far that takes you.

    Start here:
      aws sts get-caller-identity
    ================================================================
  EOT
}

###############################################################################
# Trainer answer key - everything needed to run/verify/demo the lab.
###############################################################################

resource "local_file" "trainer_notes" {
  filename        = "${path.module}/trainer_notes.txt"
  file_permission = "0600"
  content         = <<-EOT
    ================================================================
     AWS Security Lab - Overly permissive IAM policies
     TRAINER notes / answer key  (do NOT give to participants)
    ================================================================

    Region                : ${data.aws_region.current.name}
    Account               : ${data.aws_caller_identity.current.account_id}

    Overly-permissive role: ${aws_iam_role.overly_permissive.arn}
    Flag bucket           : ${aws_s3_bucket.flag.id}
    In-scope secret       : ${aws_secretsmanager_secret.in_scope.name}
    Decoy secret          : ${aws_secretsmanager_secret.decoy.name}

    Participant credentials (also in participant_credentials.txt):
      AWS_ACCESS_KEY_ID     = ${aws_iam_access_key.participant.id}
      AWS_SECRET_ACCESS_KEY = ${aws_iam_access_key.participant.secret}

    Flags:
      Bucket : FLAG{s3_bucket_read_via_overly_permissive_role}
      Secret : FLAG{secrets_manager_scoped_read_peachycloud_sec}

    Solution (as the participant):
      export AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=... AWS_DEFAULT_REGION=${data.aws_region.current.name}
      aws s3 ls                       # denied (no direct perms)
      CREDS=$(aws sts assume-role --role-arn ${aws_iam_role.overly_permissive.arn} \
              --role-session-name demo --query Credentials --output json)
      # export the returned temp creds, then:
      aws s3 cp s3://${aws_s3_bucket.flag.id}/flag.txt -
      aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.in_scope.name} --query SecretString --output text
      aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.decoy.name} --query SecretString --output text   # denied (scoping)
    ================================================================
  EOT
}
