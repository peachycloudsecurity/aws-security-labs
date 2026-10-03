resource "aws_s3_bucket" "waf_logs" {
  bucket = var.log_bucket_name
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "waf-logs-lifecycle"
    enabled = true

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      days = 90
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_iam_role" "waf_logs_delivery_role" {
  name = "waf-logs-firehose-delivery-role-${var.log_bucket_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "firehose.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name = "waf-logs-s3-policy"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect   = "Allow",
          Action   = ["s3:PutObject", "s3:GetBucketLocation", "s3:ListBucket"],
          Resource = [
            aws_s3_bucket.waf_logs.arn,
            "${aws_s3_bucket.waf_logs.arn}/*"
          ]
        }
      ]
    })
  }
}

resource "aws_kinesis_firehose_delivery_stream" "waf_logs_firehose" {
  name        = "aws-waf-logs-${var.log_bucket_suffix}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = aws_iam_role.waf_logs_delivery_role.arn
    bucket_arn         = aws_s3_bucket.waf_logs.arn
    buffering_interval = 60
    buffering_size     = 5
    compression_format = "GZIP"
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "waf_logging" {
  resource_arn           = var.waf_arn
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.waf_logs_firehose.arn]
}

resource "aws_s3_bucket" "athena_output" {
  bucket = var.athena_output
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "athena-output-lifecycle"
    enabled = true

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      days = 90
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

