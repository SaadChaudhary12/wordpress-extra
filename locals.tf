################################################################################
# Locals
################################################################################

locals {
  name                = "Saad-Vpc"
  region              = "us-east-1"
  azs                 = slice(data.aws_availability_zones.available.names, 0, length(data.aws_availability_zones.available.names))
  vpc_cidr            = "10.0.0.0/16"
  private_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets      = ["10.0.4.0/24", "10.0.5.0/24"]
  route_table_cidr    = "0.0.0.0/0"
  lb_name             = "Flask-Alb"  
  lbt                 = "application"
  health_check_path   = "/items"
  app_port            = 3000
  name_prefix_lb      = "lb-sg"
  name_prefix_web     = "App-sg"
  name_prefix_db      = "db-sg"
  name_prefix_bsg     = "bastion-sg"
  db_subnet_gn        = "main-subnet-group12"
  target_group_name   = "Flask-Alb-Tg"
  ami_id              = "ami-08982f1c5bf93d976"
  instance_type       = "t2.micro"                
  key_name            = "Saad-Flask-Key"  
  allowed_ssh_cidr    = "0.0.0.0/0"  
  storage             = "20" 
  engine_version      = "8.0"
  engine              = "mysql"
  instance_class      = "db.t3.micro"
  db_name             = "Application"
  username            = "Application"
  password            = "Application"
}
