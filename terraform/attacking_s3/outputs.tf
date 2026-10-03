output "listable_bucket" {
  description = "World-listable + readable bucket"
  value       = aws_s3_bucket.listable.id
}

output "writable_bucket" {
  description = "World-writable + readable bucket"
  value       = aws_s3_bucket.writable.id
}

output "participant_access_key_id" {
  description = "Access key for the no-permission participant (null if reusing lab 1)"
  value       = var.create_participant_user ? aws_iam_access_key.participant[0].id : null
}

output "participant_secret_access_key" {
  description = "Secret key for the no-permission participant (null if reusing lab 1)"
  value       = var.create_participant_user ? aws_iam_access_key.participant[0].secret : null
  sensitive   = true
}

output "region" {
  value = data.aws_region.current.name
}
