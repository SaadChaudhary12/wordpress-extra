################################################################################
# ELATIC-IP
################################################################################

resource "aws_eip" "this" {
  tags = { Name = "${var.name}-nat-eip" }
}


################################################################################
# NAT-GATEWAY
################################################################################

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.allocation_id
  subnet_id     = var.public_subnet_id

  tags = { Name = "${var.name}-nat" }

  depends_on = [var.internet_gateway_id]
}