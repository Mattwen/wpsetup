#!/bin/bash

# Install LAMP stack
yum install httpd -y
systemctl start httpd.service
systemctl enable httpd.service
yum install mariadb-server mariadb -y
systemctl start mariadb
mysql_secure_installation
systemctl enable mariadb.service
yum install php php-mysql -y
systemctl restart httpd.service

# Create mariadb database and user
user="root"
password="xxxxxxxxxxxxxx"
mysql --user="$user" --password="$password" --execute="CREATE DATABASE wordpress; CREATE USER wpuser@localhost IDENTIFIED BY 'Rushing2017'; GRANT ALL PRIVILEGES ON wordpress.* TO wpuser@localhost IDENTIFIED BY 'Rushing2017';"

# Install Wordpress
clear
echo "============================================"
echo "WordPress Install Script"
echo "============================================"
dbname="wordpress"
dbuser="wpuser"
dbpass="xxxxxxxxxxxxxxxx"

echo -n "run install? (y/n)"
read -e run
if [ "$run" == n ] ; then
exit
else
echo "============================================"
echo "Installing WordPress for you."
echo "============================================"
#download wordpress
curl -O https://wordpress.org/latest.tar.gz
#unzip wordpress
tar -zxvf latest.tar.gz
#change dir to wordpress
cd wordpress
#copy file to apache directory
cp -rf . /var/www/html
#move back to parent dir
rm -rf /home/rushingadmin/wordpress
#create wp config
cd /var/www/html
cp wp-config-sample.php wp-config.php
#set database details with perl find and replace
perl -pi -e "s/database_name_here/$dbname/g" wp-config.php
perl -pi -e "s/username_here/$dbuser/g" wp-config.php
perl -pi -e "s/password_here/$dbpass/g" wp-config.php

#set WP salts
perl -i -pe'
  BEGIN {
    @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
    push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
    sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
  }
  s/put your unique phrase here/salt()/ge
' wp-config.php

#create uploads folder and set permissions
mkdir wp-content/uploads
chmod 775 wp-content/uploads
chown -Rf apache:apache /var/www/html
echo "Cleaning..."

#remove zip file
# rm latest.tar.gz
#remove bash script

# Add firewall exceptions
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
sudo firewall-cmd --reload

# Turn off Selinux for mail
setenforce 0
echo "========================="
echo "Installation is complete."
echo "========================="
fi
