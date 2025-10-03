variable "launch_template_name" {}
variable "ami_id" {}
variable "instance_type" {}
variable "security_groups" {}
variable "user_data" {}
variable "desired_capacity" { default = 2 }
variable "max_size" { default = 3 }
variable "min_size" { default = 1 }
variable "target_group_arns" {}


variable "subnets" {
  description = "List of subnet IDs for autoscaling group"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for the autoscaling group"
  type        = string
}
variable "key_name" {
  description = "The name of the key pair to be used for EC2 instances"
  type        = string
}

variable "public_key" {
  description = "The public key to be used for the EC2 instances"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "Name of the existing IAM instance profile to attach to the instances"
  type        = string
}

