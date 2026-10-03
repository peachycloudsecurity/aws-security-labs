module "vpc" {
  source = "./modules/vpc"
  cidr_block = "10.0.0.0/16"
}

module "security_group" {
  source = "./modules/security-group"
  vpc_id = module.vpc.vpc_id
}

module "ec2_instance" {
  source            = "./modules/ec2"
  subnet_ids        = module.vpc.public_subnets
  security_group_id = module.security_group.security_group_id
  ami_id            = "ami-0323ead22d6752894" # Amazon Linux 2 AMI
  instance_type     = "t2.micro"
}

module "load_balancer" {
  source            = "./modules/load-balancer"
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnets
  instance_ids      = [module.ec2_instance.instance_id]
  security_group_id = module.security_group.security_group_id
}

module "waf" {
  source  = "./modules/waf"
  alb_arn = module.load_balancer.arn
}

resource "random_string" "log_bucket_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "random_string" "athena_output_suffix" {
  length  = 6
  special = false
  upper   = false
}

module "waf_logging" {
  source               = "./modules/waf_logging"
  waf_arn              = module.waf.waf_arn
  log_bucket_name      = "my-waf-logs-bucket-${random_string.log_bucket_suffix.result}"
  athena_output        = "my-athena-output-bucket-${random_string.athena_output_suffix.result}"
  log_bucket_suffix    = random_string.log_bucket_suffix.result
  athena_output_suffix = random_string.athena_output_suffix.result
  alb_arn              = module.load_balancer.arn  # Pass the ALB ARN here
}

