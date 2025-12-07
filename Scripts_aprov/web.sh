#!/bin/bash

################# CONFIGURACIÓN DEL HOSTNAME #################

hostnamectl set-hostname WEB-Wordpress-Juanma


################# INSTALACIÓN DE PAQUETES #################
apt update -y
apt install -y apache2 nfs-common php php-mysql php-gd php-xml php-mbstring php-curl php-zip php-soap php-intl libapache2-mod-php


################# MONTAJE NFS #################
# Carpeta donde se montará el contenido del WordPress
mkdir -p /var/www/

# Servidor NFS (NUEVA IP: 10.0.20.20)
echo "10.0.20.20:/var/nfs/wordpress  /var/www/  nfs  defaults  0  0" >> /etc/fstab

# Montar de inmediato
mount -a


################# CONFIGURACIÓN APACHE #################
# Nuevo VirtualHost para servir WordPress desde NFS
cat << 'EOF' > /etc/apache2/sites-available/wordpress-nfs.conf
<VirtualHost *:80>
    ServerAdmin admin@juanma.com
    ServerName juanma-aws.sytes.net
    DocumentRoot /var/www/

    <Directory /var/www/>
        AllowOverride All
        Require all granted
        Options FollowSymlinks
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/wp_error.log
    CustomLog ${APACHE_LOG_DIR}/wp_access.log combined
</VirtualHost>
EOF


################# ACTIVACIÓN DEL SITIO #################
a2dissite 000-default.conf
a2ensite wordpress-nfs.conf

systemctl reload apache2
systemctl restart apache2
