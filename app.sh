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


aws s3 cp s3://terraform-bucket-test20/app_package.zip /home/ec2-user/app_package.zip
unzip -o /home/ec2-user/app_package.zip -d /home/ec2-user/wordpress-extra/
cd /home/ec2-user/wordpress-extra
pip3 install -r requirements.txt
nohup python3 app_lt.py > app.log 2>&1 &
