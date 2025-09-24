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
  lb_name             = "WP-ALB"  
  target_group_name   = "WP-ALB-TG" 
  ami_id              = "ami-08982f1c5bf93d976"
  instance_type       = "t2.micro"                
  key_name            = "Saad-Key-WP"    
  allowed_ssh_cidr    = "0.0.0.0/0"  
  storage             = "20" 
  engine_version      = "8.0"
  instance_class      = "db.t3.micro"
  db_name             = "Application"
  username            = "Application"
  password            = "Application"



    tags = {
    Example             = local.name
    GithubRepo          = "terraform-aws-eks"
    GithubOrg           = "terraform-aws-modules"
    Environment         = "dev"
    Terraform           = "true"
  }
}
