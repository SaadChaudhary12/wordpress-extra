################################################################################
# RDS FOR FLASK APPLICATION
################################################################################

resource "aws_db_instance" "this" {
  allocated_storage      = var.allocated_storage
  skip_final_snapshot    = true
  engine                 = var.engine
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  db_name                = var.db_name
  username               = var.username
  password               = var.password
  publicly_accessible    = false
  vpc_security_group_ids = [var.db_sg_id]
  db_subnet_group_name   = var.db_subnet_group_name

  tags = {
    Name = var.name
  }
}
