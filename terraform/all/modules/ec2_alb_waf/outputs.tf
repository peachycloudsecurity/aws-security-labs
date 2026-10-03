output "vpc_id" {
  value = module.vpc.vpc_id
}

output "security_group_id" {
  value = module.security_group.security_group_id
}

output "instance_id" {
  value = module.ec2_instance.instance_id
}

output "load_balancer_dns" {
  value = module.load_balancer.dns_name
}

output "waf_arn" {
  value = module.waf.waf_arn
}

output "firehose_arn" {
  value = module.waf_logging.firehose_arn
}

output "waf_logs_bucket_arn" {
  value = module.waf_logging.waf_logs_bucket_arn
}

output "waf_logs_bucket_name" {
  value = module.waf_logging.waf_logs_bucket_name
}

output "athena_output_bucket" {
  value = module.waf_logging.athena_output_bucket
}
