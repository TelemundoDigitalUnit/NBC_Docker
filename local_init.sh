#!/bin/bash
# Load Environment Variables
source .env

# define variables
iterations=0
max_iterations=5
BASE_SCRIPT_PATH=$(pwd)
LOG_FILE=${BASE_SCRIPT_PATH}/build_log.txt
SETUP_PATH=${BASE_SCRIPT_PATH}/setup

# Colors
NC="\033[0m" # No Color
RED="\033[0;31m"
GREEN="\033[0;32m"

# check for errors
function check_error () {
    if [ $1 -ne 0 ]; then
        printf "$RED\x00An error occurred, check $LOG_FILE\n$NC"
        exit
    fi
}

# clear the error log
echo -n > $LOG_FILE

# Get parameters
source ${SETUP_PATH}/bash/getopts.sh

check_error $?

# Output to the user which project will be built
printf "$GREEN\x00😈 Compiling project: $PROJECT$NC\n"
printf "[ this may take a minute ... ]\n"

docker-compose build 1>>$LOG_FILE 2>>$LOG_FILE

check_error $?

# spin up mysql
printf "$GREEN\x00Spinning up MySQL..\n$NC"
docker-compose up -d mysql 1>>$LOG_FILE 2>>$LOG_FILE

check_error $?

# wait for mysql to be "ready"
iterations=1
while true; do
    docker-compose exec mysql /bin/sh -c "mysqlshow -p\$MYSQL_ROOT_PASSWORD" 1>>$LOG_FILE 2>>$LOG_FILE

    if [ $? -eq 0 ]; then
        break
    fi

    printf '.'

    sleep 5

    if [ $iterations -ge $max_iterations ]; then
        printf "$RED\nMySQL failed to come up after $max_iterations attempts.\n$NC"
        check_error 1
    fi

    iterations=$(expr $iterations + 1)
done;

# spin up wordpress
printf "$GREEN\x00Spinning up Wordpress..\n$NC"
docker-compose up -d wordpress 1>>$LOG_FILE 2>>$LOG_FILE

check_error $?

# wait for wordpress to be "ready"
iterations=1
while true; do
    docker-compose exec wordpress /bin/sh -c "env SCRIPT_NAME=/var/www/html/wp-admin/index.php SCRIPT_FILENAME=/var/www/html/wp-admin/index.php REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000" 1>>$LOG_FILE 2>>$LOG_FILE

    if [ $? -eq 0 ]; then
        break
    fi

    printf '.'

    sleep 5

    if [ $iterations -ge $max_iterations ]; then
        printf "$RED\nWordpress failed to come up after $max_iterations attempts.\n$NC"
        check_error 1
    fi

    iterations=$(expr $iterations + 1)
done

printf "$GREEN\x00😈 Removing WordPress wp-content folder$NC\n"
rm -Rf wp-container/wp-content

PROJECT_REPOSITORY_SSH_URL=""

if [ "$PROJECT" = "" -o "$PROJECT" = "main" ]; then
    PROJECT_REPOSITORY_SSH_URL=git@github.com-nbcsteveb:wpcomvip/nbcots.git
elif [ "$PROJECT" = "lx" -o "$PROJECT" = "localx" ]; then
    PROJECT_REPOSITORY_SSH_URL=git@github.com-nbcsteveb:wpcomvip/nbcotslx.git
fi

printf "$GREEN\x00😈 Replacing it with our VIP NBCOTS Repository$NC\n"
printf "Repo URL: %s\nBranch: %s\n" $PROJECT_REPOSITORY_SSH_URL $DEFAULT_BRANCH
printf "[ this may take a minute ... ]\n"
git clone $PROJECT_REPOSITORY_SSH_URL wp-container/wp-content/ --branch $DEFAULT_BRANCH --recurse-submodules 1>>$LOG_FILE 2>>$LOG_FILE

check_error $?

printf "$GREEN\x00😈 Pulling VIP MU Plugins\n$NC"
printf "[ this may take a minute ... ]\n"
git clone --recurse-submodules https://github.com/Automattic/vip-go-mu-plugins-built wp-container/wp-content/mu-plugins 1>>$LOG_FILE 2>>$LOG_FILE

check_error $?

command -v composer 1>>$LOG_FILE 2>>$LOG_FILE
if [ $? -eq 0 ]; then
    pushd "$BASE_SCRIPT_PATH/wp-container/wp-content"
        printf "$GREEN\x00😈 Building composer. Honeslty have no idea what this is for.\n$NC"
        composer install --no-ansi --no-dev --no-interaction --no-progress --no-scripts --optimize-autoloader
    popd
fi

printf "$GREEN\x00😈 Installing multi-site support..\n$NC"
docker-compose run wp-cli 1>>$LOG_FILE 2>>$LOG_FILE
check_error $?

docker-compose run wp-cli 1>>$LOG_FILE 2>>$LOG_FILE
check_error $?

printf "$GREEN\x00😈 Spinning up nginx and phpmyadmin\n$NC"
docker-compose up -d nginx phpmyadmin 1>>$LOG_FILE 2>>$LOG_FILE
check_error $?

printf "$GREEN\x00😈 Install node things and stealing your bank account information\n$NC"
nvm use 8
npm i -g npm@6

if [ "$SETUP_SCRIPT" != "" -a -e "$SETUP_SCRIPT" ]; then
    source "$SETUP_SCRIPT"
elif [ -e "$SETUP_PATH/bash/$PROJECT.sh" ]; then
    source "$SETUP_PATH/bash/$PROJECT.sh"
elif [ -e "$SETUP_PATH/generic/$PROJECT.sh" ]; then
    source "$SETUP_PATH/generic/$PROJECT.sh"
fi

printf "$GREEN\x00😈 Done. Maybe..\n$NC"
