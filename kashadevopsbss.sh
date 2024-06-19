#!/bin/bash
apt update -y
apt install awscli -y
apt install nginx -y
apt install php-fpm php-mysql -y
cd /var/www/html
echo "Kashadevops" > kashadevops.html
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp -r wordpress/* /var/www/html/
rm -rf wordpress
rm -rf latest.tar.gz
chmod -R 755 /var/www/html/
chown -R www-data:www-data /var/www/html/
systemctl enable nginx
