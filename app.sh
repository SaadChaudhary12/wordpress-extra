#!/bin/bash

sudo yum update -y
sudo dnf install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
sudo dnf install -y unzip awscli python3
sudo dnf install -y mariadb105-server
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo dnf install -y python3 git
sudo dnf install -y python3-pip

cd /home/ec2-user


if [ ! -d "wordpress-extra" ]; then
    git clone https://github.com/SaadChaudhary12/wordpress-extra.git
fi

DB_HOST="terraform-20251003125110284300000008.ci6pixnrgmml.us-east-1.rds.amazonaws.com"
DB_USER="Application"
DB_PASS="Application"
DB_NAME="Application"

mysql -h $DB_HOST -u $DB_USER -p$DB_PASS <<EOF

USE Application;
CREATE TABLE items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100),
  quantity INT
);

EOF


aws s3 cp s3://terraform-bucket-test20/app_package.zip /home/ec2-user/app_package.zip
unzip -o /home/ec2-user/app_package.zip -d /home/ec2-user/wordpress-extra/
cd /home/ec2-user/wordpress-extra

sudo chown -R ec2-user:ec2-user /home/ec2-user/wordpress-extra

pip3 install -r requirements.txt
nohup python3 app_lt.py > app2.log 2>&1 &
