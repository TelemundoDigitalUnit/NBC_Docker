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

function docker_compose() {
    docker-compose \
        -f docker-compose.yml \
        -f docker-compose.lx.yml \
        -f docker-compose.microsites.yml \
        $@ ;
}

function check_error () {
    if [ $1 -ne 0 ]; then
        printf "$RED\x00An error occurred, check $LOG_FILE\n$NC"
        exit
    fi
}

function clear_error_log() {
    # clear the error log
    echo -n > $LOG_FILE
}

function build_projects() {
    # builds the project
    docker_compose \
        build \
        1>>$LOG_FILE \
        2>>$LOG_FILE
}

function spin_up_mysql() {
    CONTAINER_NAME=$1

    # spin up mysql
    printf "$GREEN\x00Spinning up $CONTAINER_NAME..\n$NC"
    docker_compose up -d $CONTAINER_NAME 1>>$LOG_FILE 2>>$LOG_FILE

    check_error $?

    # wait for mysql to be "ready"
    iterations=1
    while true; do
        docker exec -it nbc-wp-$CONTAINER_NAME /bin/sh -c "mysqlshow -p\$MYSQL_ROOT_PASSWORD" 1>>$LOG_FILE 2>>$LOG_FILE

        if [ $? -eq 0 ]; then
            break
        fi

        printf '.'

        sleep 10

        if [ $iterations -ge $max_iterations ]; then
            printf "$RED\n$CONTAINER_NAME failed to come up after $max_iterations attempts.\n$NC"
            check_error 1
        fi

        iterations=$(expr $iterations + 1)
    done;
}

function spin_up_wordpress() {
    CONTAINER_NAME=$1
    CONTAINER_FOLDER=$2

    # spin up wordpress
    printf "$GREEN\x00Spinning up $CONTAINER_NAME..\n$NC"
    docker_compose up -d $CONTAINER_NAME 1>>$LOG_FILE 2>>$LOG_FILE

    check_error $?

    # wait for wordpress to be "ready"
    iterations=1
    while true; do
        docker_compose exec $CONTAINER_NAME /bin/sh -c "env SCRIPT_NAME=/var/www/html/wp-admin/index.php SCRIPT_FILENAME=/var/www/html/wp-admin/index.php REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000" 1>>$LOG_FILE 2>>$LOG_FILE

        printf "$GREEN\x00Checking if \"${CONTAINER_FOLDER}/wp-content/themes\" exists..\n$NC"
        if [ $? -eq 0 -a -e "${CONTAINER_FOLDER}/wp-content/themes" ]; then
            break
        fi

        printf '.'

        sleep 10

        if [ $iterations -ge $max_iterations ]; then
            printf "$RED\n$CONTAINER_NAME failed to come up after $max_iterations attempts.\n$NC"
            check_error 1
        fi

        iterations=$(expr $iterations + 1)
    done
}

function get_project_respository() {
    PROJECT=$1

    if [ "$PROJECT" = "" -o "$PROJECT" = "main" ]; then
        echo https://github.com/wpcomvip/nbcots.git
    elif [ "$PROJECT" = "lx" -o "$PROJECT" = "localx" ]; then
        echo https://github.com/wpcomvip/nbcotslx.git
    elif [ "$PROJECT" = "microsites" ]; then
        echo https://github.com/wpcomvip/nbcots-microsites.git
    fi
}

function clone_repo() {
    OUTPUT_PATH=$1
    REPOSITORY_URL=$2

    printf "$GREEN\x00😈 ls -lah \"$OUTPUT_PATH/wp-content/\" ...$NC\n"
    ls -lah $OUTPUT_PATH/wp-content/

    printf "$GREEN\x00😈 Cloning \"$REPOSITORY_URL\" to \"$OUTPUT_PATH/wp-content/\" ...$NC\n"
    printf "[ this may take a minute ... ]\n"
    git clone $REPOSITORY_URL $OUTPUT_PATH/wp-content/ --branch master --recurse-submodules 1>>$LOG_FILE 2>>$LOG_FILE

    check_error $?

    printf "$GREEN\x00😈 Pulling VIP MU Plugins\n$NC"
    printf "[ this may take a minute ... ]\n"
    git clone --recurse-submodules https://github.com/Automattic/vip-go-mu-plugins-built $OUTPUT_PATH/wp-content/mu-plugins 1>>$LOG_FILE 2>>$LOG_FILE

    check_error $?

    command -v composer 1>>$LOG_FILE 2>>$LOG_FILE
    if [ $? -eq 0 ]; then
        pushd "$OUTPUT_PATH/wp-content"
            printf "$GREEN\x00😈 Installing composer depedencies...\n$NC"
            composer install --no-ansi --no-dev --no-interaction --no-progress --no-scripts --optimize-autoloader
        popd
    fi
}

function install_multisite() {
    CONTAINER_NAME=$1

    printf "$GREEN\x00😈 Installing multi-site support..\n$NC"
    docker_compose run -u $(id -u):$(id -g) $CONTAINER_NAME 1>>$LOG_FILE 2>>$LOG_FILE
    check_error $?
}

function spin_up_nginx() {
    printf "$GREEN\x00😈 Spinning up nginx and phpmyadmin\n$NC"
    docker_compose up -d \
        nginx phpmyadmin \
        nginx-lx phpmyadmin-lx \
        nginx-microsites phpmyadmin-microsites \
        1>>$LOG_FILE 2>>$LOG_FILE \
    ;
    check_error $?
}

function nvm_setup() {
    printf "$GREEN\x00😈 Checking if NVM is available..\n$NC"
    type nvm 1>/dev/null 2>/dev/null

    if [ $? -ne 0 ]; then
        if [ "$NVM_DIR" != "" ]; then
            source "$NVM_DIR/nvm.sh"
        else
            echo "Could not find or load NVM.." >> $LOG_FILE
            check_error 1
        fi
    fi

    printf "$GREEN\x00😈 Checking if NVM has node 8..\n$NC"
    nvm which 8 1>/dev/null 2>/dev/null

    if [ $? -ne 0 ]; then
        nvm install 8
    fi

    nvm use 8
    npm i -g npm@6
}

function install_wp_core() {
    OUT_DIR=$1
    CORE_TEMP_PATH=/tmp/core.zip
    CORE_UNZIP_PATH=/tmp/core_unzipped
    if [ ! -e $CORE_TEMP_PATH ]; then
        wget -q -O $CORE_TEMP_PATH https://wordpress.org/latest.zip
        unzip -d $CORE_UNZIP_PATH $CORE_TEMP_PATH
        check_error $?
    fi;
    if [ ! -e $OUT_DIR ]; then
        cp -r $CORE_UNZIP_PATH/wordpress $OUT_DIR
        check_error $?
    fi;
}

function add_object_cache() {
    wget -q -O $1/wp-content/object-cache.php https://raw.githubusercontent.com/tollmanz/wordpress-pecl-memcached-object-cache/master/object-cache.php
}

function main () {
    clear_error_log

    printf "$GREEN\x00😈 Compiling projects: $PROJECT$NC\n"
    printf "[ this may take a minute ... ]\n"

    build_projects

    check_error $?

    spin_up_mysql mysql
    spin_up_mysql mysql-lx
    spin_up_mysql mysql-microsites

    install_wp_core ./wp-container
    install_wp_core ./wp-container-lx
    install_wp_core ./wp-container-microsites

    printf "fixing permissions\n";
    sudo chown -hR $(id -u):$(id -g) wp-container-*

    printf "$GREEN\x00😈 Removing WordPress wp-content folder$NC\n"
    rm -Rf \
        ./wp-container/wp-content \
        ./wp-container-lx/wp-content \
        ./wp-container-microsites/wp-content \
    ;

    clone_repo ./wp-container $(get_project_respository main)
    clone_repo ./wp-container-lx $(get_project_respository lx)
    clone_repo ./wp-container-microsites $(get_project_respository microsites)

    spin_up_wordpress wordpress ./wp-container
    spin_up_wordpress wordpress-lx ./wp-container-lx
    spin_up_wordpress wordpress-microsites ./wp-container-microsites

    install_multisite wp-cli
    install_multisite wp-cli-lx
    install_multisite wp-cli-microsites

    spin_up_nginx

    add_object_cache ./wp-container
    add_object_cache ./wp-container-lx
    add_object_cache ./wp-container-microsites

    # nvm_setup

    printf "$GREEN\x00😈 Building Themes..\n$NC"
    source $SETUP_PATH/bash/main.sh
    source $SETUP_PATH/bash/lx.sh
    source $SETUP_PATH/bash/microsites.sh

    printf "$GREEN\x00😈 Done..\n$NC"
}

main
