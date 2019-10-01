#!/bin/bash

cd /our/wp-container
rm -rf wp-content
git clone --recursive https://github.com/wpcomvip/nbcots wp-content
git clone --recurse-submodules https://github.com/Automattic/vip-go-mu-plugins-built wp-content/mu-plugins
mysql -e"create database wordpress";
wp config create --dbname=wordpress --dbuser=root --allow-root
wp core multisite-install --url=127.0.0.1 --title=Foo --admin_user=nbcdev --admin_email=admin@test.local --skip-email --allow-root
wp theme activate nbc-station --allow-root
cd wp-content
composer install
cd themes/nbc-station
nvm use 8
npm i --unsafe-perm
npm run build
cd ../../..
php -S 0:80
