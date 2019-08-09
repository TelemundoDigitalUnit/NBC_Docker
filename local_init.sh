#!/bin/bash
# Load Environment Variables
source .env

# Set the base path
BASE_SCRIPT_PATH=$(pwd)
SETUP_PATH="${BASE_SCRIPT_PATH}/setup"

# Get parameters
source ${SETUP_PATH}/bash/getopts.sh

echo "😈 Compiling project: ${PROJECT}"

# Let get the password upfront what we need to do below!
# echo '😈 I promise not to share your password with 3rd parties.. or Russia'
# sudo -v

echo '😈 Spinning up Docker and then taking a nap until state is running..'
docker-compose up -d 2>/dev/null &

until [ "$(docker inspect -f {{.State.Running}} nbc-wp-php 2>/dev/null)" == "true" ]; do
    echo -n '.'
    sleep 0.1;
done;

echo

echo '😈 Removing WordPress wp-content folder'
rm -Rf wp-container/wp-content

if [ "${PROJECT}" = "" -o "${PROJECT}" = "main" ]; then
    PROJECT_REPOSITORY_SSH_URL=https://github.com/wpcomvip/nbcots.git ;
elif [ "${PROJECT}" = "lx" ]; then
    PROJECT_REPOSITORY_SSH_URL=https://github.com/wpcomvip/nbcotslx.git ;
fi;

echo '😈 Replacing it with our VIP NBCOTS Repository'
git clone ${PROJECT_REPOSITORY_SSH_URL} wp-container/wp-content/ --branch ${DEFAULT_BRANCH} --recurse-submodules

echo '😈 Pulling VIP MU Plugins'
git clone --recurse-submodules https://github.com/Automattic/vip-go-mu-plugins-built wp-container/wp-content/mu-plugins

command -v composer >/dev/null 2>&1
if [ $? -eq 0 ]; then
    pushd "${BASE_SCRIPT_PATH}/wp-container/wp-content"
        echo "😈 Building composer. Honeslty have no idea what this is for."
        composer install --no-ansi --no-dev --no-interaction --no-progress --no-scripts --optimize-autoloader
    popd
fi

echo '😈 Install node things and stealing your bank account information'

nvm use 8
npm i -g npm@6

if [ "$SETUP_SCRIPT" != "" -a -e "$SETUP_SCRIPT" ]; then
    source "$SETUP_SCRIPT"
elif [ -e "${SETUP_PATH}/bash/${PROJECT}.sh" ]; then
    source "${SETUP_PATH}/bash/${PROJECT}.sh"
elif [ -e "${SETUP_PATH}/generic/${PROJECT}.sh" ]; then
    source "${SETUP_PATH}/generic/${PROJECT}.sh"
fi

echo '😈 Done. Maybe..'
