FROM wordpress

# Install required packages
RUN apt-get update && \
    apt-get install -y \
        wget \
        git \
        subversion \
        mariadb-client \
    ;

# Add /opt/nbc/bin to $PATH
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

# Delete the default wordpress wp-content folder.
RUN rm -rf /usr/src/wordpress/wp-content

# Set arguments for build.
ARG REPO
ARG DEFAULT_BRANCH
ARG GIT_USER
ARG GIT_TOKEN
ARG TEST_DB
ARG TEST_DB_ROOT_PWD
ARG TEST_DB_NAME

# Clone the repo
RUN git clone \
    --branch "${DEFAULT_BRANCH}" \
    --recurse-submodules \
    "https://${GIT_USER}:${GIT_TOKEN}@${REPO}" \
    /usr/src/wordpress/wp-content

# Add VIP MU (must-use) plugins.
RUN git clone \
    --recurse-submodules \
    "https://${GIT_USER}:${GIT_TOKEN}@github.com/Automattic/vip-go-mu-plugins-built" \
    /usr/src/wordpress/wp-content/mu-plugins

# Set the working directory
WORKDIR /usr/src/wordpress/wp-content

# Install wordpress test files
RUN bash bin/install-wp-tests.sh "${TEST_DB}" root "${TEST_DB_ROOT_PWD}" "${TEST_DB_NAME}" latest true

# Install composer dependencies
RUN composer install

# Set the working directory
WORKDIR /usr/src/wordpress/wp-content/themes/nbc-station

# See: https://docs.docker.com/engine/reference/builder/#cmd
CMD [ "phpunit" ]