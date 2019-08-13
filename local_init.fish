#!/usr/bin/env fish
# Load Environment Variables
cat .env | egrep -v '^(#.*)?$' | sed 's/^/set /g' | sed 's/=/ /g' | source

# Set the base path
set -l BASE_SCRIPT_PATH (pwd)
set -l SETUP_PATH $BASE_SCRIPT_PATH/setup

# Get parameters
source $SETUP_PATH/fish/getopts.fish $argv

echo "😈 Compiling project: $PROJECT"

# Let get the password upfront what we need to do below!
# echo '😈 I promise not to share your password with 3rd parties.. or Russia'
# sudo -v

echo '😈 Spinning up Docker and then taking a nap until state is running..'
docker-compose up -d 2>/dev/null &

while test (docker inspect -f '{{.State.Running}}' nbc-wp-php 2>/dev/null) != "true"
    echo -n '.'
    sleep 0.1
end

echo

echo '😈 Removing WordPress wp-content folder'
rm -Rf wp-container/wp-content

set -l PROJECT_REPOSITORY_SSH_URL ""

if [ "$PROJECT" = "" -o "$PROJECT" = "main" ];
    set PROJECT_REPOSITORY_SSH_URL https://github.com/wpcomvip/nbcots.git ;
else if [ "$PROJECT" = "lx" ];
    set PROJECT_REPOSITORY_SSH_URL https://github.com/wpcomvip/nbcotslx.git ;
end

echo '😈 Replacing it with our VIP NBCOTS Repository'
git clone $PROJECT_REPOSITORY_SSH_URL wp-container/wp-content/ --branch $DEFAULT_BRANCH --recurse-submodules

echo '😈 Pulling VIP MU Plugins'
git clone --recurse-submodules https://github.com/Automattic/vip-go-mu-plugins-built wp-container/wp-content/mu-plugins

command -v composer >/dev/null 2>&1
if [ $status -eq 0 ]
    pushd "$BASE_SCRIPT_PATH/wp-container/wp-content"
        echo "😈 Building composer. Honeslty have no idea what this is for."
        composer install --no-ansi --no-dev --no-interaction --no-progress --no-scripts --optimize-autoloader
    popd
end

echo '😈 Install node things and stealing your bank account information'

nvm use 8
npm i -g npm@6

if [ "$SETUP_SCRIPT" != "" -a -e "$SETUP_SCRIPT" ];
    source "$SETUP_SCRIPT"
else if [ -e "$SETUP_PATH/fish/$PROJECT.fish" ];
    source "$SETUP_PATH/fish/$PROJECT.fish"
else if [ -e "$SETUP_PATH/generic/$PROJECT.sh" ];
    source "$SETUP_PATH/generic/$PROJECT.sh"
end

echo '😈 Done. Maybe..'
