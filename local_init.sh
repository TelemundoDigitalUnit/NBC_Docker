#!/bin/bash

source .env

echo '😈 Give me all your base!'

# Let get the password upfront what we need to do below!
# echo '😈 I promise not to share your password with 3rd parties.. or Russia'
# sudo -v

echo '😈 Spinning up Docker and then taking a 30s nap!'
docker-compose up -d
sleep 30

echo '😈 Removing WordPress wp-content folder'
rm -Rf wp-container/wp-content

echo 'Replacing it with our VIP NBCOTS Repository'
git clone https://github.com/wpcomvip/nbcots.git wp-container/wp-content/ --branch develop --recurse-submodules

echo 'Pulling VIP MU Plugins'
git clone --recurse-submodules https://github.com/Automattic/vip-go-mu-plugins-built wp-container/wp-content/mu-plugins

echo '😈 Install node things and stealing your bank account information'
cd ./wp-container/wp-content

echo "😈 Building composer. Honeslty have no idea what this is for."
composer install --no-ansi --no-dev --no-interaction --no-progress --no-scripts --optimize-autoloader

echo '😈 Building plugin byline-manager'
cd plugins/byline-manager
npm install --quiet
npm run build
cd ..

echo '😈 Building plugin nbc-library'
cd nbc-library
npm install --quiet
npm run build -s
cd ..
cd ..

echo '😈 Building theme nbc-station'
nvm use 8
npm i -g npm@6
cd themes/nbc-station
npm install --quiet
npm run build -s

echo 'Done. Maybe..'  
