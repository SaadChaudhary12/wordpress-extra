output "vpc_id" {
  value       = aws_vpc.this.id
  description = "The ID of the VPC"
}

output "public_ids" {
  value       = aws_subnet.public[*].id
  description = "IDs of all public subnets"
}

output "private_ids" {
  value       = aws_subnet.private[*].id
  description = "IDs of all private subnets"
}

output "internet_gateway_id" {
  value       = aws_internet_gateway.this.id
  description = "ID of the Internet Gateway"
}

output "nat_gateway_id" {
  value       = aws_nat_gateway.this.id
  description = "ID of the NAT Gateway"
}

