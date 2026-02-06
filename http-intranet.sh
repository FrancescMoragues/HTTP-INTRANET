#!/bin/bash

# ==========================================
# 1. INSTALACIÓN Y MÓDULOS
# ==========================================
sudo apt update && sudo apt install apache2 apache2-utils -y
sudo a2enmod cgi authz_host

# ==========================================
# 2. CONFIGURACIÓN: app.intranet.kuy.com
# ==========================================
# Variables
ROOT_INTRA="/var/www/appintranet"
PRIV_INTRA="/srv/www/appintranet/privado"
LOGS_INTRA="$ROOT_INTRA/logs"

# Crear estructura
sudo mkdir -p $ROOT_INTRA $PRIV_INTRA $LOGS_INTRA

# Contenido mínimo y Error 404
echo "<h1>Aplicacion: app.intranet.kuy.com</h1>" | sudo tee $ROOT_INTRA/index.html
echo "<h1>Directorio Privado - Intranet</h1>" | sudo tee $PRIV_INTRA/index.html
echo "Error en la aplicacion web appintranet - archivo no encontrado" | sudo tee $ROOT_INTRA/404.html

# Usuarios (Contraseña: 1234)
sudo htpasswd -bc /etc/apache2/.htpasswd_intra Usuari01 1234
sudo htpasswd -b /etc/apache2/.htpasswd_intra Usuari02 1234
sudo htpasswd -b /etc/apache2/.htpasswd_intra Usuari03 1234

# VirtualHost
sudo bash -c "cat <<EOF > /etc/apache2/sites-available/intranet.conf
<VirtualHost *:80>
    ServerName www.intranet.kuy.com
    ServerAlias aplicacion.intranet.kuy.com
    ServerAdmin contacto@kuy.com
    DocumentRoot $ROOT_INTRA

    ErrorDocument 404 /404.html
    ErrorLog $LOGS_INTRA/error.log
    CustomLog $LOGS_INTRA/access.log combined

    Alias /privado $PRIV_INTRA
    <Directory $PRIV_INTRA>
        AuthType Basic
        AuthName \"Acces Restringit Usuaris Intra\"
        AuthUserFile /etc/apache2/.htpasswd_intra
        Require valid-user
        # Solo accesible desde la propia red (ejemplo IP del servidor)
        Require ip 127.0.0.1 10.18.70.0/24
    </Directory>
</VirtualHost>
EOF"

# ==========================================
# 3. CONFIGURACIÓN: app.sistema.kuy.org
# ==========================================
# Variables
ROOT_SIST="/var/www/appsistema"
PRIV_SIST="/srv/www/appsistema/privado"
LOGS_SIST="$ROOT_SIST/logs"

# Crear estructura
sudo mkdir -p $ROOT_SIST $PRIV_SIST $LOGS_SIST

# Contenido mínimo y Error 404
echo "<h1>Aplicacion: app.sistema.kuy.org</h1>" | sudo tee $ROOT_SIST/index.html
echo "Error en la aplicacion web appsistema - archivo no encontrado" | sudo tee $ROOT_SIST/404.html

# Scripts CGI
for s in uptime free vmstat top atop; do
    echo -e "#!/bin/bash\necho \"Content-type: text/plain\"\necho\n$s" | sudo tee $ROOT_SIST/$s.sh
    sudo chmod +x $ROOT_SIST/$s.sh
done

# Usuarios Sistema (Contraseña: 1234)
sudo htpasswd -bc /etc/apache2/.htpasswd_sist Usuari04 1234
sudo htpasswd -b /etc/apache2/.htpasswd_sist Usuari05 1234
sudo htpasswd -b /etc/apache2/.htpasswd_sist Usuari06 1234

# VirtualHost
sudo bash -c "cat <<EOF > /etc/apache2/sites-available/sistema.conf
<VirtualHost *:80>
    ServerName www.sistema.kuy.org
    ServerAlias aplicacion.sistema.kuy.org
    ServerAdmin contacto@kuy.org
    DocumentRoot $ROOT_SIST

    ErrorDocument 404 /404.html
    ErrorLog $LOGS_SIST/error.log
    CustomLog $LOGS_SIST/access.log combined

    <Directory $ROOT_SIST>
        Options +ExecCGI
        AddHandler cgi-script .sh
        AuthType Basic
        AuthName \"Acces Restringit Administracio\"
        AuthUserFile /etc/apache2/.htpasswd_sist
        Require valid-user
    </Directory>
</VirtualHost>
EOF"

# ==========================================
# 4. ACTIVACIÓN Y REINICIO
# ==========================================
sudo a2ensite intranet.conf sistema.conf
sudo systemctl restart apache2


echo "Configuración de Intranet G8 completada."
