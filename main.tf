################################################################################
# VPC FULL SET-UP
################################################################################

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

resource "aws_vpc" "main" {
  cidr_block = local.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = local.name
  }
}

resource "aws_subnet" "public_subnets" {
  count                         = length(local.public_subnets)
  vpc_id                        = aws_vpc.main.id
  cidr_block                    = local.public_subnets[count.index]
  availability_zone             = local.azs[count.index]
  map_public_ip_on_launch       = true

  tags = {
    Name = "${local.name}-Public Subnet-${count.index}"
  }
} 

resource "aws_subnet" "private_subnets" {
  count                         = length(local.private_subnets)
  vpc_id                        = aws_vpc.main.id
  cidr_block                    = local.private_subnets[count.index]
  availability_zone             = local.azs[count.index]
  map_public_ip_on_launch       = false
  
  tags = {
    Name = "${local.name}-Private Subnet-${count.index}"
  }
} 

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name}-igw"
  }
}

resource "aws_eip" "nat" {

  tags = {
    Name = "${local.name}-nat-eip"
  }
}


resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.allocation_id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = {
    Name = "${local.name}-nat"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = local.route_table_cidr
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${local.name}-public-rt"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = local.route_table_cidr
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${local.name}-private-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private.id
}


################################################################################
# RDS FOR FLASK APPLICATION
################################################################################

resource "aws_db_subnet_group" "mains" {
  name        = "main-subnet-group1"
  subnet_ids  = aws_subnet.private_subnets[*].id
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
  db_subnet_group_name = aws_db_subnet_group.mains.name
}

################################################################################
# EC2 FOR WORDPRESS/FLASK-APP
################################################################################

resource "aws_instance" "this" {
  ami                    = local.ami_id
  instance_type          = local.instance_type
  subnet_id              = aws_subnet.public_subnets[0].id
  associate_public_ip_address = true
  key_name               = local.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOT
            #!/bin/bash
            set -e

            # Update system
            sudo yum update -y

            sudo dnf install nginx -y
            sudo systemctl start nginx
            sudo systemctl enable nginx

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
  subnets                     = aws_subnet.public_subnets[*].id
  enable_deletion_protection  = false
  enable_cross_zone_load_balancing = true
  drop_invalid_header_fields  = true
}

resource "aws_lb_target_group" "main" {
  vpc_id      = aws_vpc.main.id
  name        = local.target_group_name
  port        = 80
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
  vpc_id      = aws_vpc.main.id
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
  vpc_id            = aws_vpc.main.id
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
  vpc_id = aws_vpc.main.id
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