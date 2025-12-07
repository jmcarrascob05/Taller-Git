#!/bin/bash
set -euo pipefail

# Configuración del hostname para Juanma
sudo hostnamectl set-hostname NFSJuanma

# Actualización del sistema y instalación del servidor NFS
sudo apt-get update
sudo apt-get install -y nfs-kernel-server unzip wget

# Creación del directorio compartido para WordPress
sudo mkdir -p /srv/nfs/wordpress
sudo chown nobody:nogroup /srv/nfs/wordpress

# Configuración de exportaciones NFS para los servidores web
cat >> /etc/exports << EOF
/srv/nfs/wordpress 10.0.20.10(rw,sync,no_subtree_check,no_root_squash)
/srv/nfs/wordpress 10.0.20.11(rw,sync,no_subtree_check,no_root_squash)
EOF

# Descarga e instalación de WordPress en el directorio NFS
cd /tmp
sudo wget -q https://wordpress.org/latest.zip
sudo unzip -q latest.zip -d /srv/nfs/
sudo rm latest.zip

# Configuración de permisos específicos para Apache
sudo chown -R www-data:www-data /srv/nfs/wordpress
sudo chmod -R 755 /srv/nfs/wordpress
sudo find /srv/nfs/wordpress -type f -exec chmod 644 {} +

# Aplicación de configuraciones NFS y reinicio del servicio
sudo exportfs -ra
sudo systemctl enable nfs-kernel-server
sudo systemctl restart nfs-kernel-server

# Verificación del servicio
sudo systemctl status nfs-kernel-server --no-pager -l | grep Active
