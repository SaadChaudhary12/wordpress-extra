variable "iam_role_name" {
  description = "Name of the IAM role for EC2"
  type        = string
}

variable "secrets_arn" {
  description = "ARN of the Secrets Manager secret to allow access"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket to allow access"
  type        = string
}
