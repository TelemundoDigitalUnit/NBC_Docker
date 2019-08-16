#!/usr/bin/env fish
# Load Environment Variables
cat .env | egrep -v '^(#.*)?$' | sed 's/^/set /g' | sed 's/=/ /g' | source

# define variables
set -l iterations 0
set -l max_iterations 5
set -l BASE_SCRIPT_PATH (pwd)
set -lx LOG_FILE $BASE_SCRIPT_PATH/build_log.txt
set -l SETUP_PATH $BASE_SCRIPT_PATH/setup

# Colors
set -l NC "\033[0m" # No Color
set -l RED "\033[0;31m"
set -l GREEN "\033[0;32m"

# check for errors
function check_error
    if [ $argv -ne 0 ]
        printf "$RED\x00An error occurred, check $LOG_FILE\n$NC"
        exit
    end
end

# clear the error log
echo -n > $LOG_FILE

# Get parameters
source $SETUP_PATH/fish/getopts.fish $argv

check_error $status

# Output to the user which project will be built
printf "$GREEN😈 Compiling project: $PROJECT$NC\n"
printf "[ this may take a minute ... ]\n"

docker-compose build 1>>$LOG_FILE 2>>$LOG_FILE

check_error $status

# spin up mysql
printf "$GREEN\x00Spinning up MySQL..\n$NC"
docker-compose up -d mysql 1>>$LOG_FILE 2>>$LOG_FILE

check_error $status

# wait for mysql to be "ready"
set iterations 1
while true
    docker-compose exec mysql /bin/sh -c "mysqlshow -p\$MYSQL_ROOT_PASSWORD" 1>>$LOG_FILE 2>>$LOG_FILE

    if [ $status -eq 0 ]
        break
    end

    printf '.'

    sleep 5

    if [ $iterations -ge $max_iterations ]
        printf "$RED\nMySQL failed to come up after $max_iterations attempts.\n$NC"
        check_error 1
    end

    set iterations (expr $iterations + 1)
end

# spin up wordpress
printf "$GREEN\x00Spinning up Wordpress..\n$NC"
docker-compose up -d wordpress 1>>$LOG_FILE 2>>$LOG_FILE

check_error $status

# wait for wordpress to be "ready"
set iterations 1
while true
    docker-compose exec wordpress /bin/sh -c "env SCRIPT_NAME=/var/www/html/wp-admin/index.php SCRIPT_FILENAME=/var/www/html/wp-admin/index.php REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000" 1>>$LOG_FILE 2>>$LOG_FILE

    if [ $status -eq 0 ]
        break
    end

    printf '.'

    sleep 5

    if [ $iterations -ge $max_iterations ]
        printf "$RED\nWordpress failed to come up after $max_iterations attempts.\n$NC"
        check_error 1
    end

    set iterations (expr $iterations + 1)
end

printf "$GREEN😈 Removing WordPress wp-content folder$NC\n"
rm -Rf wp-container/wp-content

set -l PROJECT_REPOSITORY_SSH_URL ""

if [ "$PROJECT" = "" -o "$PROJECT" = "main" ];
    set PROJECT_REPOSITORY_SSH_URL https://github.com/wpcomvip/nbcots.git ;
else if [ "$PROJECT" = "lx" -o "$PROJECT" = "localx" ];
    set PROJECT_REPOSITORY_SSH_URL https://github.com/wpcomvip/nbcotslx.git ;
end

printf "$GREEN😈 Replacing it with our VIP NBCOTS Repository$NC\n"
printf "Repo URL: %s\nBranch: %s\n" $PROJECT_REPOSITORY_SSH_URL $DEFAULT_BRANCH
printf "[ this may take a minute ... ]\n"
git clone $PROJECT_REPOSITORY_SSH_URL wp-container/wp-content/ --branch $DEFAULT_BRANCH --recurse-submodules 1>>$LOG_FILE 2>>$LOG_FILE

check_error $status

printf "$GREEN😈 Pulling VIP MU Plugins\n$NC"
printf "[ this may take a minute ... ]\n"
git clone --recurse-submodules https://github.com/Automattic/vip-go-mu-plugins-built wp-container/wp-content/mu-plugins 1>>$LOG_FILE 2>>$LOG_FILE

check_error $status

command -v composer 1>>$LOG_FILE 2>>$LOG_FILE
if [ $status -eq 0 ]
    pushd "$BASE_SCRIPT_PATH/wp-container/wp-content"
        printf "$GREEN😈 Building composer. Honeslty have no idea what this is for.\n$NC"
        composer install --no-ansi --no-dev --no-interaction --no-progress --no-scripts --optimize-autoloader
    popd
end

printf "$GREEN😈 Installing multi-site support..\n$NC"
docker-compose run wp-cli 1>>$LOG_FILE 2>>$LOG_FILE
check_error $status

printf "$GREEN😈 Spinning up nginx and phpmyadmin\n$NC"
docker-compose up -d nginx phpmyadmin 1>>$LOG_FILE 2>>$LOG_FILE
check_error $status

printf "$GREEN😈 Install node things and stealing your bank account information\n$NC"
nvm use 8
npm i -g npm@6

if [ "$SETUP_SCRIPT" != "" -a -e "$SETUP_SCRIPT" ];
    source "$SETUP_SCRIPT"
else if [ -e "$SETUP_PATH/fish/$PROJECT.fish" ];
    source "$SETUP_PATH/fish/$PROJECT.fish"
else if [ -e "$SETUP_PATH/generic/$PROJECT.sh" ];
    source "$SETUP_PATH/generic/$PROJECT.sh"
end

printf "$GREEN😈 Done. Maybe..\n$NC"
