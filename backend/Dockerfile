# Laravel 12 API for Render (Docker runtime — Render has no native PHP).
# Apache + mod_php, document root pointed at public/, Postgres (Supabase) driver.
FROM php:8.2-apache

# --- System deps + PHP extensions -------------------------------------------
# pdo_pgsql/pgsql: Supabase Postgres. zip/bcmath: Laravel + composer.
RUN apt-get update && apt-get install -y --no-install-recommends \
        libpq-dev libzip-dev zip unzip git \
    && docker-php-ext-install pdo_pgsql pgsql zip bcmath \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Composer (from the official image).
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# --- Apache: serve public/, allow .htaccess, enable rewrite -----------------
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
    && printf '<Directory ${APACHE_DOCUMENT_ROOT}>\n    AllowOverride All\n    Require all granted\n</Directory>\n' > /etc/apache2/conf-available/laravel.conf \
    && a2enconf laravel \
    && a2enmod rewrite headers

WORKDIR /var/www/html

# --- PHP dependencies (cached layer) ----------------------------------------
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist --no-interaction

# --- App code ---------------------------------------------------------------
COPY . .
RUN composer dump-autoload --optimize --no-dev --no-interaction \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Startup: bind Apache to Render's $PORT, cache config, migrate, then serve.
COPY docker/start.sh /usr/local/bin/start.sh
RUN sed -i 's/\r$//' /usr/local/bin/start.sh && chmod +x /usr/local/bin/start.sh

CMD ["/usr/local/bin/start.sh"]
