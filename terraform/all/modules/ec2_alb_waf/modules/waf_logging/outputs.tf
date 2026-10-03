
output "firehose_arn" {
  value = aws_kinesis_firehose_delivery_stream.waf_logs_firehose.arn
}

output "waf_logs_bucket_arn" {
  value = aws_s3_bucket.waf_logs.arn
}

output "waf_logs_bucket_name" {
  value = aws_s3_bucket.waf_logs.bucket
}

output "athena_output_bucket" {
  value = aws_s3_bucket.athena_output.bucket
}