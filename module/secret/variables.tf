variable "secret_name" {
  description = "Name of the secret"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_host" {
  description = "Database host (from RDS output)"
  type        = string
}
