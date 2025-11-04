FROM prestashop/prestashop:9.0.1

# Build arguments to control environment
ARG INSTALL_XDEBUG=true
ARG PHP_MEMORY_LIMIT=512M
ARG PHP_UPLOAD_MAX_FILESIZE=64M
ARG PHP_POST_MAX_SIZE=64M
ARG PHP_MAX_EXECUTION_TIME=600
ARG PHP_MAX_INPUT_VARS=10000

# Install useful PHP extensions for production
RUN apt-get update && apt-get install -y \
    libzip-dev \
    zip \
    unzip \
    && docker-php-ext-install opcache \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Conditional Xdebug installation (dev only)
RUN if [ "$INSTALL_XDEBUG" = "true" ]; then \
    yes | pecl install xdebug \
    && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.client_port=9000" >> /usr/local/etc/php/conf.d/xdebug.ini; \
    fi

# OPcache is configured dynamically via entrypoint.sh
# This allows flexible configuration via environment variables

# Permissions
RUN usermod -u 1000 www-data && chown -R www-data:www-data /var/www

# Entrypoint script to generate PHP config dynamically
COPY entrypoint.sh /usr/local/bin/prestashop-entrypoint.sh
RUN chmod +x /usr/local/bin/prestashop-entrypoint.sh

# Default environment variables for PHP
ENV PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT} \
    PHP_UPLOAD_MAX_FILESIZE=${PHP_UPLOAD_MAX_FILESIZE} \
    PHP_POST_MAX_SIZE=${PHP_POST_MAX_SIZE} \
    PHP_MAX_EXECUTION_TIME=${PHP_MAX_EXECUTION_TIME} \
    PHP_MAX_INPUT_VARS=${PHP_MAX_INPUT_VARS} \
    PHP_DISPLAY_ERRORS=On \
    PHP_ERROR_REPORTING=E_ALL \
    PHP_OPCACHE_VALIDATE_TIMESTAMPS=0

EXPOSE 80
ENTRYPOINT ["/usr/local/bin/prestashop-entrypoint.sh"]
CMD ["apache2-foreground"]
