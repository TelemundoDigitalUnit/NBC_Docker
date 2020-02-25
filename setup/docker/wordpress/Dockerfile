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
    pecl install memcache memcached xdebug \
    && docker-php-ext-enable memcache \
    && docker-php-ext-enable memcached \
    && docker-php-ext-enable xdebug \
    && echo "xdebug.profiler_enable=0" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.profiler_output_dir=/tmp" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_autostart=on" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_port=$xdebug_port" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_handler=dbgp" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_connect_back=0" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_host=docker.for.mac.localhost" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
;

# install composer
RUN EXPECTED_CHECKSUM="$(curl -Ls https://composer.github.io/installer.sig)" \
    && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
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
