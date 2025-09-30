################################################################################
# Outputs
################################################################################

output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnets" {
  value = aws_subnet.private_subnets[*].id
}

output "public_subnets" {
  value = aws_subnet.public_subnets[*].id
}

output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}






                #   user_data = <<-EOT
                #     #!/bin/bash
                #     sudo dnf install wget php-mysqlnd httpd php-fpm php-mysqli mariadb105-server php-json php-devel php-gd -y
                #     sudo wget https://wordpress.org/latest.tar.gz
                #     sudo tar -xzf latest.tar.gz
                #     cd wordpress
                #     sudo cp wp-config-sample.php wp-config.php
                #     sudo sed -i "s/database_name_here/wordpress/" wp-config.php
                #     sudo sed -i "s/username_here/wordpress/" wp-config.php
                #     sudo sed -i "s/password_here/wordpress/" wp-config.php
                #     sudo sed -i "s/localhost/${aws_db_instance.rds_endpoint}/" wp-config.php
                #     cd ..
                #     sudo cp -r wordpress/* /var/www/html/
                #     sudo chown -R apache:apache /var/www
                #     sudo chmod -R 755 /var/www
                #     sudo systemctl start httpd
                #     sudo systemctl enable httpd
                # EOT