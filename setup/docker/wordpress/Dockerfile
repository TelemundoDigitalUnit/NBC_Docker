FROM wordpress:5.2.2-fpm

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
    && echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_autostart=on" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_port=9001" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_handler=dbgp" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_connect_back=0" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_host=docker.for.mac.localhost" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
;