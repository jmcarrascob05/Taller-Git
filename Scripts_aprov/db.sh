#!/bin/bash
set -euo pipefail

# Configuración del hostname para Juanma
sudo hostnamectl set-hostname DBJuanma

# Actualización del sistema e instalación de MariaDB Server
sudo apt-get update
sudo apt-get install -y mariadb-server

# Creación de base de datos y usuarios para WordPress
sudo mysql -e "
CREATE DATABASE juanmawordpress;
CREATE USER 'juanma'@'10.0.30.%' IDENTIFIED BY '1234';
GRANT ALL PRIVILEGES ON juanmawordpress.* TO 'juanma'@'10.0.30.%';
FLUSH PRIVILEGES;
"

# Configuración del bind-address para la subred de base de datos
sudo sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf

# Persistencia del servicio y reinicio
sudo systemctl enable mariadb
sudo systemctl restart mariadb

# Verificación del servicio y conectividad
sudo systemctl status mariadb --no-pager -l | grep Active
sudo mysql -u root -e "SHOW DATABASES;" | grep juanmawordpress
