#!/bin/bash
# load variables from .env file
export $(cat unit_test.env | sed 's/#.*$//g' | xargs)

# Don't change unless you're absolute sure of what you're doing.
TEST_PATH=/tmp/wordpress-tests-lib

# Functions

create_network() {
    docker network ls -q -f name="${TEST_NETWORK}" --format="{{.Name}}" | grep "${TEST_NETWORK}" 1>/dev/null

    if [ $? -ne 0 ]; then
        docker network create "${TEST_NETWORK}";
    fi
}

run_mysql() {
    # Check if the test database container is running
    docker ps -q --format="{{.Names}}" | grep "${MYSQL_CONTAINER_NAME}" 1>/dev/null

    # If not, start it
    if [ $? -ne 0 ]; then
        docker run \
            --rm \
            --network="${TEST_NETWORK}" \
            --network-alias="${MYSQL_CONTAINER_NAME}" \
            -d \
            -e MYSQL_DATABASE="${TEST_DB}" \
            -e MYSQL_ROOT_PASSWORD="${TEST_DB_ROOT_PWD}" \
            -p "${LOCAL_PORT}:${CONTAINER_PORT}" \
            --name="${MYSQL_CONTAINER_NAME}" \
            "${DB_IMAGE}" \
        ; 1>/dev/null
    fi

    # Wait for it to really be up
    TIMES_WAITED=0
    while [ true ]; do
        docker exec -it "${MYSQL_CONTAINER_NAME}" /bin/sh -c "echo 'SHOW DATABASES;' | mysql -p'${TEST_DB_ROOT_PWD}' '${TEST_DB}'" 1>/dev/null
        if [ $TIMES_WAITED -gt ${MAX_WAITS} ]; then
            echo "mysql container took too long to come up."
            exit 1
        fi

        if [ $? -eq 0 ]; then
            break
        fi
        echo -n '.'
        TIMES_WAITED=`expr $TIMES_WAITED + 1`
        sleep ${TIME_TO_WAIT}
    done
    echo
};

run_phpunit() {
    docker build \
        -f unit_test.Dockerfile \
        --network="${TEST_NETWORK}" \
        --build-arg REPO="${REPO}" \
        --build-arg DEFAULT_BRANCH="${DEFAULT_BRANCH}" \
        --build-arg GIT_USER="${GIT_USER}" \
        --build-arg GIT_TOKEN="${GIT_TOKEN}" \
        --build-arg TEST_DB="${TEST_DB}" \
        --build-arg TEST_DB_ROOT_PWD="${TEST_DB_ROOT_PWD}" \
        --build-arg TEST_DB_NAME="${MYSQL_CONTAINER_NAME}" \
        -t "${UNIT_TEST_BASE_IMAGE}" \
        . \
    ;

    docker run \
        --rm \
        -it \
        --network="${TEST_NETWORK}" \
        --network-alias="${UNIT_TEST_CONTAINER_NAME}" \
        --name="${UNIT_TEST_CONTAINER_NAME}" \
        "${UNIT_TEST_BASE_IMAGE}" \
    ;
};

main() {
    create_network
    run_mysql
    run_phpunit
};

# Run it
main
echo "Done"