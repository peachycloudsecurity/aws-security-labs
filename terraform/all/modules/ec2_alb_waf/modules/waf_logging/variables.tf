
variable "alb_arn" {
  description = "The ARN of the Application Load Balancer"
  type        = string
}

variable "log_bucket_name" {
  description = "The name of the S3 bucket for WAF logs"
  type        = string
}

variable "athena_output" {
  description = "The name of the S3 bucket for Athena query output"
  type        = string
}

variable "log_bucket_suffix" {
  description = "Suffix for log bucket naming"
  type        = string
}

variable "athena_output_suffix" {
  description = "Suffix for Athena output bucket naming"
  type        = string
}

variable "waf_arn" {
  description = "The ARN of the WAF Web ACL"
  type        = string
}
