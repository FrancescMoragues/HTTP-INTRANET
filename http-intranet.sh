#!/bin/bash

# ==========================================
# 1. INSTAL·LACIÓ I MODULS
# ==========================================
sudo apt update && sudo apt install apache2 apache2-utils -y
sudo a2enmod cgi authz_host

# ==========================================
# 2. VARIABLES DE XARXA (Basat en la teva IP 192.168.3.84)
# ==========================================
IP_SRV="192.168.3.84"
GW="192.168.3.1"  # Exemple de Gateway per a la teva xarxa
XARXA_INTRA="192.168.3.0/24"

# ==========================================
# 3. CONFIGURACIÓ: intranet.primernomdedomini.com
# ==========================================
ROOT_INTRA="/var/www/appintranet"
PRIV_INTRA="/var/www/appintranet/privado" # Canviat de /srv a /var per seguretat
LOGS_INTRA="$ROOT_INTRA/logs"

sudo mkdir -p $ROOT_INTRA $PRIV_INTRA $LOGS_INTRA

echo "<h1>Aplicacio: intranet.primernomdedomini.com</h1>" | sudo tee $ROOT_INTRA/index.html
echo "<h1>Directori Privat - Intranet Segura</h1>" | sudo tee $PRIV_INTRA/index.html
echo "Error en la aplicacion web appintranet - archivo no encontrado" | sudo tee $ROOT_INTRA/404.html

# Usuaris (Contrasenya: 1234)
sudo htpasswd -bc /etc/apache2/.htpasswd_intra Usuari01 1234
sudo htpasswd -b /etc/apache2/.htpasswd_intra Usuari02 1234

sudo bash -c "cat <<EOF > /etc/apache2/sites-available/intranet.conf
<VirtualHost *:80>
    ServerName intranet.primernomdedomini.com
    DocumentRoot $ROOT_INTRA

    ErrorDocument 404 /404.html
    ErrorLog $LOGS_INTRA/error.log
    CustomLog $LOGS_INTRA/access.log combined

    <Directory $ROOT_INTRA>
        Options -Indexes +FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    <Directory $PRIV_INTRA>
        AuthType Basic
        AuthName \"Acces Restringit Usuaris Intra\"
        AuthUserFile /etc/apache2/.htpasswd_intra
        Require valid-user
        # RESTRICCIÓ D'IP CORRECTA PER A LA TEVA XARXA
        Require ip 127.0.0.1 $IP_SRV $XARXA_INTRA
    </Directory>
</VirtualHost>
EOF"

# ==========================================
# 4. CONFIGURACIÓ: sistema.segonnomdedomini.org
# ==========================================
ROOT_SIST="/var/www/appsistema"
LOGS_SIST="/var/log/apache2/appsistema"

sudo mkdir -p $ROOT_SIST $LOGS_SIST

echo "<h1>Aplicacion: sistema.segonnomdedomini.org</h1>" | sudo tee $ROOT_SIST/index.html
echo "Error en la aplicacion web appsistema - archivo no encontrado" | sudo tee $ROOT_SIST/404.html

# Scripts CGI (Per a la Passa 3)
for s in uptime free vmstat; do
    echo -e "#!/bin/bash\necho \"Content-type: text/plain\"\necho\n$s" | sudo tee $ROOT_SIST/$s.sh
    sudo chmod +x $ROOT_SIST/$s.sh
done

# Usuaris Sistema (Contrasenya: 1234)
sudo htpasswd -bc /etc/apache2/.htpasswd_sist Usuari04 1234

sudo bash -c "cat <<EOF > /etc/apache2/sites-available/sistema.conf
<VirtualHost *:80>
    ServerName sistema.segonnomdedomini.org
    DocumentRoot $ROOT_SIST

    ErrorDocument 404 /404.html
    ErrorLog \${APACHE_LOG_DIR}/sistema-error.log
    CustomLog \${APACHE_LOG_DIR}/sistema-access.log combined

    <Directory $ROOT_SIST>
        Options +ExecCGI
        AddHandler cgi-script .sh
        AuthType Basic
        AuthName \"Acces Administracio\"
        AuthUserFile /etc/apache2/.htpasswd_sist
        Require valid-user
    </Directory>
</VirtualHost>
EOF"

# ==========================================
# 5. ACTIVACIÓ, PERMISOS I REINICI
# ==========================================
sudo chown -R www-data:www-data /var/www/
sudo a2dissite 000-default.conf
sudo a2ensite intranet.conf sistema.conf
sudo systemctl restart apache2

echo "✅ Intranet configurada. IP SRV: $IP_SRV | GW: $GW"
