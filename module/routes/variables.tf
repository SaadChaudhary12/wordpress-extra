variable "name"              { type = string }
variable "vpc_id"            { type = string }
variable "route_table_cidr"  { type = string }
variable "internet_gateway_id" { type = string }
variable "nat_gateway_id"    { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids"{ type = list(string) }
