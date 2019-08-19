FROM wordpress:5.2.2-fpm

# add fast-cgi bin for healthcheck
RUN apt-get update && apt-get install -y libfcgi-bin

RUN apt-get install -y \
        libz-dev \
        libmemcached-dev \
    && \
    if [ -n "$http_proxy" ]; then \
        pecl config-set http_proxy $http_proxy; \
    fi; \
    pecl install memcached && \
    docker-php-ext-enable memcached ;
