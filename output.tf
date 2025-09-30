################################################################################
# Outputs
################################################################################

output "vpc_id" {
  value = module.vpc.id
}

output "private_subnets" {
  value = module.subnets.private_ids
}

output "public_subnets" {
  value = module.subnets.public_ids
}

output "rds_endpoint" {
  value = module.rds.endpoint
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