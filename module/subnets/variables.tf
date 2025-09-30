variable "vpc_id"           { type = string }
variable "name"             { type = string }
variable "public_subnets"   { type = list(string) }
variable "private_subnets"  { type = list(string) }
