FROM wordpress:5.3-fpm

# add fast-cgi bin for healthcheck
RUN apt-get update && apt-get install -y libfcgi-bin

RUN apt-get install -y \
        libz-dev \
        libmemcached-dev \
    && \
    if [ -n "$http_proxy" ]; then \
        pear config-set http_proxy $(echo -n $http_proxy | sed 's/^https\?:\/\///'); \
        pecl config-set http_proxy $(echo -n $http_proxy | sed 's/^https\?:\/\///'); \
    fi; \
    pecl install memcache memcached \
    && docker-php-ext-enable memcache \
    && docker-php-ext-enable memcached \
;

# install composer
RUN EXPECTED_CHECKSUM="$(curl -Ls https://composer.github.io/installer.sig)" \
    && curl -o composer-setup.php https://getcomposer.org/installer \
    && ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")" \
    && if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then \
        >&2 echo 'ERROR: Invalid installer checksum' \
        rm composer-setup.php \
        && exit 1; \
    fi \
    && php composer-setup.php --quiet \
    && rm composer-setup.php \
    && mv composer.phar /usr/local/bin/composer \
;
