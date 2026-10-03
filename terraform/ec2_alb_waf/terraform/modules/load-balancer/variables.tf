variable "vpc_id" {
  description = "VPC ID"
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security Group ID"
}

variable "instance_ids" {
  description = "Instance IDs"
  type        = list(string)
}
