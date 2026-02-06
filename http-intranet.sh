#!/bash/bin

sudo apt update && sudo apt install apache2 apache2-utils -y

sudo mkdir -p /var/log/intranet
sudo mkdir -p /var/log/www

ROOT_INTRA="/srv/erebor/intranet"
PRIV_INTRA="/var/erebor/privat"

sudo mkdir -p $ROOT_INTRA $PRIV_INTRA

echo "<h1>Benvingut a intranet.erebor.com</h1>" | sudo tee $ROOT_INTRA/index.html
echo "<h1>Zona Privada</h1>" | sudo tee $PRIV_INTRA/index.html

sudo htpasswd -bc /etc/apache2/.htpasswd_erebor guimli 1234
sudo htpasswd -b /etc/apache2/.htpasswd_erebor eomar 1234
sudo htpasswd -b /etc/apache2/.htpasswd_erebor faramir 1234
sudo htpasswd -b /etc/apache2/.htpasswd_erebor sauron 1234

sudo bash -c "cat <<EOF > /etc/apache2/sites-available/intranet_erebor.conf
<VirtualHost *:80>
    ServerName intranet.erebor.com
    DocumentRoot $ROOT_INTRA

    # Logs segons l'enunciat
    ErrorLog /var/log/intranet/error.log
    CustomLog /var/log/intranet/access.log combined

    # Configuració recurs / (Arrel)
    <Directory $ROOT_INTRA>
        Options -Indexes +FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    # Configuració recurs /private -> /var/erebor/privat
    Alias /private $PRIV_INTRA
    <Directory $PRIV_INTRA>
        AuthType Basic
        AuthName \"Acces Restringit Erebor\"
        AuthUserFile /etc/apache2/.htpasswd_erebor
        Require user guimli eomar faramir sauron
    </Directory>
</VirtualHost>
EOF"

ROOT_WWW="/srv/erebor/www"
IMG_WWW="/var/log/www"

sudo mkdir -p $ROOT_WWW $IMG_WWW

echo "<h1>Benvingut a www.erebor.com</h1>" | sudo tee $ROOT_WWW/index.html
echo "<h1>Directori d'Imatges</h1>" | sudo tee $IMG_WWW/index.html

sudo bash -c "cat <<EOF > /etc/apache2/sites-available/www_erebor.conf
<VirtualHost *:80>
    ServerName www.erebor.com
    DocumentRoot $ROOT_WWW

    # Logs (usant el directori de l'enunciat)
    ErrorLog /var/log/www/error_www.log
    CustomLog /var/log/www/access_www.log combined

    # Configuració recurs / (Arrel)
    <Directory $ROOT_WWW>
        Options -Indexes +FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    # Configuració recurs /img -> /var/log/www
    Alias /img $IMG_WWW
    <Directory $IMG_WWW>
        Require all granted
    </Directory>
</VirtualHost>
EOF"

sudo chown -R www-data:www-data /srv/erebor /var/erebor /var/log/intranet /var/log/www

sudo a2dissite 000-default.conf
sudo a2ensite intranet_erebor.conf www_erebor.conf

sudo systemctl restart apache2

echo "Configuració finalitzada."
