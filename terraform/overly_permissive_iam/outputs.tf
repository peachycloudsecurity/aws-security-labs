output "participant_access_key_id" {
  description = "Access key ID handed to the participant"
  value       = aws_iam_access_key.participant.id
}

output "participant_secret_access_key" {
  description = "Secret access key handed to the participant"
  value       = aws_iam_access_key.participant.secret
  sensitive   = true
}

output "overly_permissive_role_arn" {
  description = "The role with the Principal:* trust policy"
  value       = aws_iam_role.overly_permissive.arn
}

output "flag_bucket_name" {
  description = "S3 bucket holding the flag"
  value       = aws_s3_bucket.flag.id
}

output "in_scope_secret_name" {
  value = aws_secretsmanager_secret.in_scope.name
}

output "decoy_secret_name" {
  value = aws_secretsmanager_secret.decoy.name
}

output "region" {
  value = local.region
}
