FROM wordpress:cli

# drop to root
USER root

# install memached
RUN apk update \
    && apk add \
        autoconf \
        g++ \
        gcc \
        libmemcached-dev \
        make \
        zlib-dev; \
    if [ -n "$http_proxy" ]; then \
        pear config-set http_proxy $(echo -n $http_proxy | sed 's/^https\?:\/\///'); \
        pecl config-set http_proxy $(echo -n $http_proxy | sed 's/^https\?:\/\///'); \
    fi; \
    pecl install memcache memcached \
    && docker-php-ext-enable memcache \
    && docker-php-ext-enable memcached \
;

# switch the user back
USER www-data
