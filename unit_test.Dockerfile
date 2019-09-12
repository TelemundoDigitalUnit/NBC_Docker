FROM wordpress

RUN apt-get update && \
    apt-get install -y \
        wget \
        git \
        subversion \
        mariadb-client \
    ;

ENV PATH="/opt/nbc/bin:${PATH}"

# install phpunit (see: https://make.wordpress.org/core/handbook/testing/automated-testing/phpunit/)
RUN mkdir -p /opt/nbc/bin && \
    wget https://phar.phpunit.de/phpunit-7.5.phar && \
    chmod +x phpunit-7.5.phar && \
    mv phpunit-7.5.phar /opt/nbc/bin/phpunit && \
    phpunit --version

# install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php -r "if (hash_file('sha384', 'composer-setup.php') === 'a5c698ffe4b8e849a443b120cd5ba38043260d5c4023dbf93e1558871f1f07f58274fc6f4c93bcfd858c6bd0775cd8d1') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /opt/nbc/bin/composer

RUN rm -rf /usr/src/wordpress/wp-content

ARG DEFAULT_BRANCH
ARG GIT_USER
ARG GIT_TOKEN
ARG TEST_DB
ARG TEST_DB_ROOT_PWD
ARG TEST_DB_NAME

RUN git clone \
    --branch "${DEFAULT_BRANCH}" \
    --recurse-submodules \
    "https://${GIT_USER}:${GIT_TOKEN}@github.com/wpcomvip/nbcots.git" \
    /usr/src/wordpress/wp-content

RUN git clone \
    --recurse-submodules \
    "https://${GIT_USER}:${GIT_TOKEN}@github.com/Automattic/vip-go-mu-plugins-built" \
    /usr/src/wordpress/wp-content/mu-plugins

WORKDIR /usr/src/wordpress/wp-content

RUN bash bin/install-wp-tests.sh "${TEST_DB}" root "${TEST_DB_ROOT_PWD}" "${TEST_DB_NAME}" latest true

RUN composer install

WORKDIR /usr/src/wordpress/wp-content/themes/nbc-station

CMD [ "phpunit" ]