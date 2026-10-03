###############################################################################
# Module: overly_permissive_iam
# Role with Principal:* trust + S3 read + scoped Secrets Manager read, a flag
# bucket and target/decoy secrets. The shared participant/trainer users (created
# by the root) assume this role.
###############################################################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  bucket_name = "peachycloud-${var.suffix}"
  region      = data.aws_region.current.name
  account_id  = data.aws_caller_identity.current.account_id
}

resource "aws_iam_role" "overly_permissive" {
  name = "peachycloud-overly-permissive-role-${var.suffix}"

  # MISCONFIGURATION: any principal can assume this role.
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
        Sid      = "ListSecrets"
        Effect   = "Allow"
        Action   = "secretsmanager:ListSecrets"
        Resource = "*"
      },
      {
        Sid      = "ReadScopedSecrets"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        Resource = "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:peachycloud_sec_*"
      }
    ]
  })
}

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

resource "aws_secretsmanager_secret" "in_scope" {
  name                    = "peachycloud_sec_flag_${var.suffix}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "in_scope" {
  secret_id     = aws_secretsmanager_secret.in_scope.id
  secret_string = "FLAG{secrets_manager_scoped_read_peachycloud_sec}"
}

resource "aws_secretsmanager_secret" "decoy" {
  name                    = "internal_db_password_${var.suffix}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "decoy" {
  secret_id     = aws_secretsmanager_secret.decoy.id
  secret_string = "SHOULD-NOT-BE-READABLE-super-secret-db-password"
}
