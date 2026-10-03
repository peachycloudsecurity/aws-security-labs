###############################################################################
# Module: attacking_s3
# Two public buckets: one world-listable+readable, one world-writable+readable.
###############################################################################

locals {
  listable_bucket = "peachycloud-listable-${var.suffix}"
  writable_bucket = "peachycloud-writable-${var.suffix}"
}

# ---- Bucket 1: world LISTABLE + readable ----
resource "aws_s3_bucket" "listable" {
  bucket        = local.listable_bucket
  force_destroy = true
}

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
      Resource  = [aws_s3_bucket.listable.arn, "${aws_s3_bucket.listable.arn}/*"]
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

# ---- Bucket 2: world WRITABLE + readable ----
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
