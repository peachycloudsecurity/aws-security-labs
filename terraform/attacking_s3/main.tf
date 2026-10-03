###############################################################################
# Lab: Attacking S3 buckets
#
# Two SEPARATE intentionally-public buckets:
#   - peachycloud-listable-<rand>  : world-LISTABLE + readable (Principal "*")
#                                    -> anyone can list objects and read the flag
#   - peachycloud-writable-<rand>  : world-WRITABLE + readable (Principal "*")
#                                    -> anyone can upload objects (and read the flag)
#
# The participant uses the SAME no-permission IAM user from the first lab. Because
# the buckets are public (resource-based policy with Principal "*"), IAM identity
# permissions are irrelevant - even a zero-permission user (or anonymous) gets in.
# That is the lesson.
#
# Reuse: if the "Overly permissive IAM" lab is already deployed, set
#   create_participant_user = false
# and hand out those existing credentials instead.
#
# WARNING: creates PUBLIC buckets (one world-writable). Deploy only in an isolated
# lab account and destroy promptly - a public writable bucket can be abused by
# anyone on the internet.
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
      Lab     = "attacking_s3"
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
  listable_bucket = "peachycloud-listable-${random_string.suffix.result}"
  writable_bucket = "peachycloud-writable-${random_string.suffix.result}"
}

###############################################################################
# Participant user (same "no permissions" user as the first lab).
# Toggle off to reuse the first lab's credentials instead.
###############################################################################

resource "aws_iam_user" "participant" {
  count         = var.create_participant_user ? 1 : 0
  name          = "peachycloud-participant"
  force_destroy = true
}

resource "aws_iam_access_key" "participant" {
  count = var.create_participant_user ? 1 : 0
  user  = aws_iam_user.participant[0].name
}

# Intentionally NO policies attached - this user has zero IAM permissions.

resource "local_file" "participant_credentials" {
  count           = var.create_participant_user ? 1 : 0
  filename        = "${path.module}/participant_credentials.txt"
  file_permission = "0600"
  content         = <<-EOT
    ================================================================
     AWS Security Lab - Attacking S3 buckets
     Participant credentials  (keep these private)
    ================================================================

    AWS_ACCESS_KEY_ID     = ${aws_iam_access_key.participant[0].id}
    AWS_SECRET_ACCESS_KEY = ${aws_iam_access_key.participant[0].secret}
    AWS_DEFAULT_REGION    = ${data.aws_region.current.name}

    This IAM user has NO permissions at all. See how far that still gets
    you against misconfigured S3 buckets.
    ================================================================
  EOT
}

###############################################################################
# Bucket 1 - world LISTABLE + readable
###############################################################################

resource "aws_s3_bucket" "listable" {
  bucket        = local.listable_bucket
  force_destroy = true
}

# Allow a public bucket policy on THIS bucket.
resource "aws_s3_bucket_public_access_block" "listable" {
  bucket                  = aws_s3_bucket.listable.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "listable" {
  bucket     = aws_s3_bucket.listable.id
  depends_on = [aws_s3_bucket_public_access_block.listable]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicListAndRead"
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:ListBucket", "s3:GetObject"]
      Resource = [
        aws_s3_bucket.listable.arn,
        "${aws_s3_bucket.listable.arn}/*"
      ]
    }]
  })
}

resource "aws_s3_object" "listable_flag" {
  bucket  = aws_s3_bucket.listable.id
  key     = "flag.txt"
  content = "FLAG{s3_public_listable_bucket}\n"
}

resource "aws_s3_object" "listable_decoy1" {
  bucket  = aws_s3_bucket.listable.id
  key     = "notes/todo.txt"
  content = "remember to lock this bucket down...\n"
}

resource "aws_s3_object" "listable_decoy2" {
  bucket  = aws_s3_bucket.listable.id
  key     = "backup/users.csv"
  content = "id,name\n1,alice\n2,bob\n"
}

###############################################################################
# Bucket 2 - world WRITABLE + readable
###############################################################################

resource "aws_s3_bucket" "writable" {
  bucket        = local.writable_bucket
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "writable" {
  bucket                  = aws_s3_bucket.writable.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "writable" {
  bucket     = aws_s3_bucket.writable.id
  depends_on = [aws_s3_bucket_public_access_block.writable]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicWriteAndRead"
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:PutObject", "s3:GetObject"]
      Resource  = "${aws_s3_bucket.writable.arn}/*"
    }]
  })
}

resource "aws_s3_object" "writable_flag" {
  bucket  = aws_s3_bucket.writable.id
  key     = "flag.txt"
  content = "FLAG{s3_public_writable_bucket}\n"
}

resource "aws_s3_object" "writable_readme" {
  bucket  = aws_s3_bucket.writable.id
  key     = "README.txt"
  content = "This bucket is writable by anyone. Prove it: upload a file here.\n"
}
