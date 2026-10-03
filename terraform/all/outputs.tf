# --- Overly-permissive IAM lab ---
output "overly_permissive_role_arn" { value = module.overly.role_arn }
output "flag_bucket"                { value = module.overly.flag_bucket }
output "in_scope_secret"            { value = module.overly.in_scope_secret }
output "decoy_secret"               { value = module.overly.decoy_secret }

# --- Attacking S3 lab ---
output "listable_bucket" { value = module.s3.listable_bucket }
output "writable_bucket" { value = module.s3.writable_bucket }

# --- EC2 & ALB / WAF lab ---
output "load_balancer_dns" { value = module.ec2_alb_waf.load_balancer_dns }
output "waf_logs_bucket_name" { value = module.ec2_alb_waf.waf_logs_bucket_name }
output "athena_output_bucket" { value = module.ec2_alb_waf.athena_output_bucket }

# --- Shared users ---
output "participant_access_key_id" { value = aws_iam_access_key.lab["participant"].id }
output "participant_secret_access_key" {
  value     = aws_iam_access_key.lab["participant"].secret
  sensitive = true
}
output "trainer_access_key_id" { value = aws_iam_access_key.lab["trainer"].id }
output "trainer_secret_access_key" {
  value     = aws_iam_access_key.lab["trainer"].secret
  sensitive = true
}
