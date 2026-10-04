terraform {
  required_version = ">= 1.3"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.0" }
    local  = { source = "hashicorp/local", version = "~> 2.0" }
    time   = { source = "hashicorp/time", version = "~> 0.9" }
  }
}

# Default: IAM + S3 labs in us-east-1
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Project = "aws-security-labs"
      Managed = "terraform"
    }
  }
}

# EC2/ALB/WAF lab lives in us-west-2
provider "aws" {
  alias  = "usw2"
  region = "us-west-2"
  default_tags {
    tags = {
      Project = "aws-security-labs"
      Managed = "terraform"
    }
  }
}
