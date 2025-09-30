################################################################################
# PUBLIC ROUTE TABLE
################################################################################
resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = var.route_table_cidr
    gateway_id = var.internet_gateway_id
  }

  tags = {
    Name = "${var.name}-public-rt"
  }
}

################################################################################
# PRIVATE ROUTE TABLE
################################################################################
resource "aws_route_table" "private" {
  vpc_id = var.vpc_id

  route {
    cidr_block     = var.route_table_cidr
    nat_gateway_id = var.nat_gateway_id
  }

  tags = {
    Name = "${var.name}-private-rt"
  }
}

################################################################################
# PUBLIC ROUTE ASSOCIATION
################################################################################
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_ids)
  subnet_id      = var.public_subnet_ids[count.index]
  route_table_id = aws_route_table.public.id
}

################################################################################
# PRIVATE ROUTE ASSOCIATION
################################################################################
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_ids)
  subnet_id      = var.private_subnet_ids[count.index]
  route_table_id = aws_route_table.private.id
}
