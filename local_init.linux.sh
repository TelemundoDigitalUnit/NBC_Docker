#!/bin/bash
# This isn't really a script, just a reference.

# To begin with, you have a choice. You can clone the repos directly into the container, but it becomes time-consuming
# to troubleshoot Dockerfile problems this way. Alternatively, you can clone the repos into your host and copy them
# into the container:
#
# docker cp wp-content linux:/our/wp-container/wp-content
#
# Delete the wp-content directory if you want a fresh clone.

mysql -e"create database wordpress; create user wordpress identified by 'wordpress'; grant all privileges on wordpress.* to wordpress@'%' with grant option; flush privileges;";

# This requires mysql to be running.
cd /our/wp-container && wp config create --dbname=wordpress --dbuser=wordpress --dbpass=wordpress --dbcharset=utf8mb4 --allow-root --extra-php="define( 'GUTENBERG_USE_PLUGIN', true );"

cd /our/wp-container && wp core multisite-install --url="$LOCAL_DEV_DOMAIN" --title="$WP_SITE_TITLE" --admin_user="$WP_ADMIN_USER" --admin_password="$WP_ADMIN_PASSWORD" --admin_email="$WP_ADMIN_EMAIL" --skip-email --skip-themes --allow-root

if [ ! -d /our/wp-container/wp-content/mu-plugins ]
then
    rm -rf /our/wp-container/wp-content
    git clone --recursive --recurse-submodules https://github.com/wpcomvip/nbcots /our/wp-container/wp-content
    git clone --recursive --recurse-submodules https://github.com/Automattic/vip-go-mu-plugins-built /our/wp-container/wp-content/mu-plugins
fi

cd /our/wp-container && wp theme activate nbc-station --allow-root

cd /our/wp-container/wp-content && composer install

cd /our/wp-container/wp-content/mu-plugins && composer install

cd /our/wp-container/wp-content/themes/nbc-station && nvm use 8 && npm i -g npm@6

apt-get update && apt-get install -y --quiet phpmyadmin && apt-get clean

