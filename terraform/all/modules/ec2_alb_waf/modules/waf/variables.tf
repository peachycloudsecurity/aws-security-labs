variable "waf_name" {
  description = "The name of the WAF"
  default     = "my-waf"
}

variable "alb_arn" {
  description = "The ARN of the ALB to associate the WAF with"
}
