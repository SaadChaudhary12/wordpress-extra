################################################################################
# VPC
################################################################################

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}

################################################################################
# RDS FOR FLASK APPLICATION
################################################################################

resource "aws_db_subnet_group" "mains" {
  name        = "main-subnet-group"
  subnet_ids  = module.vpc.private_subnets
}


resource "aws_db_instance" "main" {
  allocated_storage    = local.storage
  skip_final_snapshot = true
  engine               = "mysql"
  engine_version       = local.engine_version
  instance_class       = local.instance_class
  db_name              = local.db_name
  username             = local.username
  password             = local.password
  publicly_accessible  = false
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name = "main-subnet-group"
}

################################################################################
# EC2 FOR WORDPRESS/FLASK-APP
################################################################################

resource "aws_instance" "this" {
  ami                    = local.ami_id
  instance_type          = local.instance_type
  subnet_id              = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  key_name               = local.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOT
            #!/bin/bash
            set -e

            # Update system
            sudo yum update -y

            sudo yum install -y mariadb105-server
            sudo systemctl start mariadb
            sudo systemctl enable mariadb

            # Install dependencies
            sudo yum install -y python3 git
            sudo yum install -y python3-pip

            # Clone your repo
            cd /home/ec2-user
            if [ ! -d "wordpress-extra" ]; then
              git clone https://github.com/SaadChaudhary12/wordpress-extra.git
            fi

            cd wordpress-extra

  EOT



  tags = { Name = "Saad-ec2" }
}

################################################################################
# EC2 FOR DATABASE
################################################################################

# resource "aws_instance" "thiss" {
#   ami                    = local.ami_id
#   instance_type          = local.instance_type
#   subnet_id              = module.vpc.private_subnets[0]
#   key_name               = local.key_name
#   vpc_security_group_ids = [aws_security_group.db_sg.id]

#   user_data = <<-EOT
#     #!/bin/bash
#     sudo dnf install -y mariadb105-server
#     sudo systemctl start mariadb
#     sudo systemctl enable mariadb
#     mysql -e "CREATE DATABASE wordpress;"
#     mysql -e "CREATE USER 'wordpress'@'%' IDENTIFIED BY 'wordpress';"
#     mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'%';"
#     mysql -e "FLUSH PRIVILEGES;"

#   EOT

#   tags = { Name = "Saad-DB-ec2" }
# }

################################################################################
# LOAD BALANCER
################################################################################

resource "aws_lb" "main" {
  name                        = local.lb_name
  internal                    = false
  load_balancer_type          = "application"
  security_groups             = [aws_security_group.lb_sg.id]
  subnets                     = module.vpc.public_subnets
  enable_deletion_protection  = false
  enable_cross_zone_load_balancing = true
  drop_invalid_header_fields  = true
}

resource "aws_lb_target_group" "main" {
  vpc_id      = module.vpc.vpc_id
  name        = local.target_group_name
  port        = 8000
  protocol    = "HTTP"
  
  health_check {
    path                = "/items"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

################################################################################
# SECURITY-GROUPS
################################################################################


resource "aws_security_group" "lb_sg" {     
  vpc_id      = module.vpc.vpc_id
  name_prefix = "lb-sg"
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

resource "aws_security_group" "web_sg" {
  vpc_id            = module.vpc.vpc_id
  name_prefix       = "App-sg"
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  ingress {
    description      = "from ALB"
    from_port        = 8000
    to_port          = 8000
    protocol         = "tcp"
    security_groups  = [aws_security_group.lb_sg.id]
  }
    # Allow SSH traffic
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    # Allow ALL inbound traffic
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

resource "aws_security_group" "db_sg" {
  vpc_id = module.vpc.vpc_id
  name   = "db-sg"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}