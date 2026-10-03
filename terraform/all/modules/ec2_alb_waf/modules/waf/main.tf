resource "aws_wafv2_web_acl" "main" {
  name        = var.waf_name
  scope       = "REGIONAL"
  description = "Peachycloudsecurity WAF for ALB"
  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      sampled_requests_enabled = true
      cloudwatch_metrics_enabled = true
      metric_name = "AWSManagedRulesCommonRuleSet"
    }
  }

  rule {
    name     = "AWSManagedRulesLinuxRuleSet"
    priority = 200

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesLinuxRuleSet"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      sampled_requests_enabled = true
      cloudwatch_metrics_enabled = true
      metric_name = "AWSManagedRulesLinuxRuleSet"
    }
  }

  rule {
    name     = "AWSManagedRulesPHPRuleSet"
    priority = 100

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesPHPRuleSet"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      sampled_requests_enabled = true
      cloudwatch_metrics_enabled = true
      metric_name = "AWSManagedRulesPHPRuleSet"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name = "webACL"
    sampled_requests_enabled = true
  }

  tags = {
    Name = "peachycloudsecurity_waf-main"
  }
}

resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}
