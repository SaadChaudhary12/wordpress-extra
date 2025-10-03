################################################################################
# AVAILABILITY ZONES
################################################################################

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

################################################################################
# MODULE-VPC
################################################################################

module "vpc" {
  source           = "./module/vpc"
  name             = local.name
  vpc_cidr         = local.vpc_cidr
  public_subnets   = local.public_subnets
  private_subnets  = local.private_subnets
  route_table_cidr = local.route_table_cidr
}

################################################################################
# MODULE-RDS
################################################################################

module "rds" {
  source               = "./module/rds"
  name                 = local.name
  allocated_storage    = local.storage
  engine               = local.engine
  engine_version       = local.engine_version
  instance_class       = local.instance_class
  db_name              = local.db_name
  username             = local.username
  password             = local.password
  db_sg_id             = aws_security_group.db_sg.id
  db_subnet_group_name = aws_db_subnet_group.mains.name
}

resource "aws_db_subnet_group" "mains" {
  name       = local.db_subnet_gn
  subnet_ids = module.vpc.private_ids
}

################################################################################
# MODULE-AUTO SCALING GROUP
################################################################################


module "autoscaling" {
  source               = "./module/autoscaling"
  launch_template_name = "App-template"
  ami_id               = local.ami_id
  instance_type        = local.instance_type
  security_groups      = [aws_security_group.web_sg.id]
  user_data            = base64encode(templatefile("./app.sh", {}))
  desired_capacity     = 0
  max_size             = 2
  min_size             = 1
  subnets              = module.vpc.private_ids[0]
  vpc_id               = module.vpc.vpc_id
  target_group_arns    = [module.loadbalancer.target_group_arn]
  key_name             = local.key_name
  public_key           = ""
  iam_instance_profile_name = ""
}

################################################################################
# MODULE-LOAD BALANCER
################################################################################

module "alb" {
  source            = "./module/alb"
  lb_name           = local.lb_name
  lb_type           = local.lbt
  security_group_id = aws_security_group.lb_sg.id
  subnet_ids        = module.vpc.public_ids
  vpc_id            = module.vpc.vpc_id
  target_group_name = local.target_group_name
  app_port          = local.app_port
  health_check_path = local.health_check_path
  instance_id       = aws_instance.this.id
}

################################################################################
# SECURITY-GROUP FOR LOAD-BALANCER
################################################################################

resource "aws_security_group" "lb_sg" {
  vpc_id      = module.vpc.vpc_id
  name_prefix = local.name_prefix_lb

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

################################################################################
# SECURITY-GROUP FOR APPLICATION / EC2
################################################################################

resource "aws_security_group" "web_sg" {
  vpc_id      = module.vpc.vpc_id
  name_prefix = local.name_prefix_web

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  ingress {
    description     = "from ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

################################################################################
# SECURITY-GROUP FOR DATA-BASE
################################################################################

resource "aws_security_group" "db_sg" {
  vpc_id = module.vpc.vpc_id
  name   = local.name_prefix_db

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [
      aws_security_group.web_sg.id,
      aws_security_group.bastion_sg.id
      ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "bastion_sg" {
  vpc_id      = module.vpc.vpc_id
  name_prefix = local.name_prefix_bsg

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ################################################################################
# # EC2 FOR WORDPRESS/FLASK-APP
# ################################################################################

# resource "aws_instance" "this" {
#   ami                         = local.ami_id
#   instance_type               = local.instance_type
#   subnet_id                   = module.vpc.private_ids[0]
#   key_name                    = local.key_name
#   vpc_security_group_ids      = [aws_security_group.web_sg.id]

#   user_data = <<-EOT
#             #!/bin/bash
#             sudo yum update -y

#             sudo dnf install nginx -y
#             sudo systemctl start nginx
#             sudo systemctl enable nginx

#             sudo dnf install -y mariadb105-server
#             sudo systemctl start mariadb
#             sudo systemctl enable mariadb

#             sudo dnf install -y python3 git
#             sudo dnf install -y python3-pip

#             cd /home/ec2-user
#             if [ ! -d "wordpress-extra" ]; then
#               git clone https://github.com/SaadChaudhary12/wordpress-extra.git
#             fi
#   EOT

#   tags = { Name = "Saad-App-ec2" }
# }

# ################################################################################
# # EC2 FOR DATABASE/BASTION
# ################################################################################

# resource "aws_instance" "thiss" {
#   ami                    = local.ami_id
#   instance_type          = local.instance_type
#   subnet_id              = module.vpc.public_ids[0]
#   associate_public_ip_address = true
#   key_name               = local.key_name
#   vpc_security_group_ids = [aws_security_group.bastion_sg.id]

#   # user_data = <<-EOT
#   #   #!/bin/bash
#   #   sudo dnf install -y mariadb105-server
#   #   sudo systemctl start mariadb
#   #   sudo systemctl enable mariadb
#   #   mysql -e "CREATE DATABASE wordpress;"
#   #   mysql -e "CREATE USER 'wordpress'@'%' IDENTIFIED BY 'wordpress';"
#   #   mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'%';"
#   #   mysql -e "FLUSH PRIVILEGES;"

#   # EOT
#   tags = { Name = "Saad-Bastion-ec2" }
# }