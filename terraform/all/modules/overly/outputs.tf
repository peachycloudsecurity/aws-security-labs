output "role_arn"        { value = aws_iam_role.overly_permissive.arn }
output "role_name"       { value = aws_iam_role.overly_permissive.name }
output "flag_bucket"     { value = aws_s3_bucket.flag.id }
output "in_scope_secret" { value = aws_secretsmanager_secret.in_scope.name }
output "decoy_secret"    { value = aws_secretsmanager_secret.decoy.name }
