# Dockerfile for Laravel 12 + Filament on Render
FROM php:8.3-fpm-alpine

# Install base packages
RUN apk add --no-cache nginx bash curl git ca-certificates

# Install PHP extensions using the official extension installer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions pdo_mysql mbstring zip intl bcmath gd opcache

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy project files
COPY . .

# Install composer dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts

# Setup directories and permissions
RUN mkdir -p /var/www/html/storage/framework/sessions \
             /var/www/html/storage/framework/views \
             /var/www/html/storage/framework/cache \
             /var/www/html/bootstrap/cache \
    && chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Copy Nginx configuration
COPY ./nginx.conf /etc/nginx/http.d/default.conf

# Copy entrypoint script and ensure Unix line endings
COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh && chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8000

CMD ["/usr/local/bin/entrypoint.sh"]
