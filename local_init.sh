#!/bin/bash

source .env

echo '😈 Give me all your base!'

# Let get the password upfront what we need to do below!
echo '😈 I promise not to share your password with 3rd parties.. or Russia'
sudo -v

echo '😈 Spinning up Docker and then taking a 30s nap!'
docker-compose up -d
sleep 30

echo '😈 Removing WordPress wp-content folder'
rm -Rf wp-container/wp-content

echo 'Replacing it with our VIP NBCOTS Repository'
git clone $PROJECT_REPOSITORY_SSH_URL --recursive wp-container/wp-content/

# Check to see if this is a VIP Installation
if $IS_VIP_ENV
then
    git clone -q https://github.com/Automattic/vip-go-mu-plugins.git --recursive wp-container/wp-content/mu-plugins
fi

echo '😈 Install node things and stealing your bank account information'
cd ./wp-container/wp-content

echo "😈 Building composer. Honeslty have no idea what this is for."
composer install --no-ansi --no-dev --no-interaction --no-progress --no-scripts --optimize-autoloader

echo '😈 Run all the scripts! For node... I think...'
chmod +x bin/script-build.sh

echo '😈 Building plugin byline-manager'
cd plugins/byline-manager && npm install --quiet && npm run build && cd ..

echo '😈 Building plugin nbc-library'
cd nbc-library
npm install --quiet
npm run build
cd ..
cd ..

echo '😈 Building theme nbc-station'
. ~/.nvm/nvm.sh install 8
npm i -g npm@6
cd themes/nbc-station
npm install --quiet
npm run build

echo 'Done. Maybe..'  
