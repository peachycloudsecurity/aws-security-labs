variable "ami_id" {
  description = "AMI ID"
}

variable "instance_type" {
  description = "Instance type"
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security Group ID"
}
