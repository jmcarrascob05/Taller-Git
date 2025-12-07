#!/bin/bash

############# CONFIGURACIÓN INICIAL #############
# Establecer nombre del host
hostnamectl set-hostname LB-Wordpress-Juanma

# Actualización del sistema e instalación de Apache
apt update -y
apt install -y apache2

# Activación de los módulos necesarios para balanceo y SSL
a2enmod proxy
a2enmod proxy_http
a2enmod proxy_balancer
a2enmod lbmethod_byrequests
a2enmod ssl
a2enmod headers
a2enmod proxy_connect

systemctl restart apache2


############# CONFIGURACIÓN DE VHOST HTTP (REDIRECCIÓN) #############
cat << 'EOF' > /etc/apache2/sites-available/balancer-http.conf
<VirtualHost *:80>
    ServerName juanma-aws.sytes.net
    ServerAdmin admin@juanma.com

    # Redirección de HTTP a HTTPS
    Redirect "/" "https://juanma-aws.sytes.net/"

    ErrorLog ${APACHE_LOG_DIR}/lb_http_error.log
    CustomLog ${APACHE_LOG_DIR}/lb_http_access.log combined
</VirtualHost>
EOF


############# CONFIGURACIÓN SSL + BALANCEO #############
cat << 'EOF' > /etc/apache2/sites-available/balancer-https.conf
<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerName juanma-aws.sytes.net
    ServerAdmin admin@juanma.com

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/juanma-aws.sytes.net/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/juanma-aws.sytes.net/privkey.pem
    Include /etc/letsencrypt/options-ssl-apache.conf

    # Definición del clúster
    <Proxy "balancer://clusterwp">
        BalancerMember "http://10.0.20.10:80"
        BalancerMember "http://10.0.20.11:80"
        ProxySet lbmethod=byrequests
    </Proxy>

    ProxyPass        "/" "balancer://clusterwp/"
    ProxyPassReverse "/" "balancer://clusterwp/"

    ErrorLog ${APACHE_LOG_DIR}/lb_ssl_error.log
    CustomLog ${APACHE_LOG_DIR}/lb_ssl_access.log combined
</VirtualHost>
</IfModule>
EOF


############# ACTIVACIÓN DE LOS SITIOS #############
a2dissite 000-default.conf
a2ensite balancer-http.conf
a2ensite balancer-https.conf

systemctl reload apache2
systemctl restart apache2
