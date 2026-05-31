FROM php:8.3-fpm-alpine AS php_base

WORKDIR /var/www/html

RUN apk add --no-cache \
        freetype \
        icu-libs \
        libjpeg-turbo \
        libpng \
        libzip \
        postgresql-libs \
    && apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        freetype-dev \
        icu-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libzip-dev \
        postgresql-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
        bcmath \
        exif \
        gd \
        intl \
        opcache \
        pcntl \
        pdo_mysql \
        pdo_pgsql \
        zip \
    && apk del .build-deps

FROM php_base AS vendor

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY composer.json composer.lock ./
COPY app app
COPY artisan artisan
COPY bootstrap bootstrap
COPY config config
COPY database database
COPY lang lang
COPY public public
COPY resources resources
COPY routes routes

RUN composer install \
    --no-dev \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader

FROM node:22-alpine AS assets

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY resources resources
COPY public public
COPY vite.config.js ./
RUN npm run build

FROM php_base AS app

# Install nginx, supervisor, and envsubst (gettext)
RUN apk add --no-cache nginx supervisor gettext \
    && mkdir -p /var/log/nginx /var/log/supervisor /var/run

# Copy application code from vendor stage
COPY --from=vendor /var/www/html /var/www/html

# Copy built assets
COPY --from=assets /app/public/build /var/www/html/public/build

# Set up storage directories, symlink, and permissions
RUN mkdir -p /var/www/html/storage/app/public \
              /var/www/html/storage/framework/cache \
              /var/www/html/storage/framework/sessions \
              /var/www/html/storage/framework/views \
              /var/www/html/storage/logs \
              /var/www/html/bootstrap/cache \
    && ln -snf ../storage/app/public /var/www/html/public/storage \
    && chown -R www-data:www-data /var/www/html/storage \
                                 /var/www/html/bootstrap/cache

# Copy nginx, PHP-FPM, supervisor, and entrypoint configs
COPY docker/nginx-default.conf /etc/nginx/templates/default.conf.template
COPY docker/php-fpm-pool.conf /usr/local/etc/php-fpm.d/zz-docker.conf
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
