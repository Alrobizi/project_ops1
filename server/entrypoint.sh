#!/bin/bash
set -e

echo "Starting deployment setup..."

# Run package discover and filament upgrade now that ENV is present
php artisan package:discover --ansi || true
php artisan filament:upgrade || true

# Link storage
php artisan storage:link || true

# Run database migrations if DB_HOST is set
if [ -n "$DB_HOST" ] && [ "$DB_CONNECTION" != "sqlite" ]; then
    echo "Running database migrations on TiDB..."
    php artisan migrate --force || echo "Migration warning: could not finish migrations."
fi

# Cache config & routes
php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true

echo "Starting PHP-FPM and Nginx on port 8000..."
php-fpm -D
nginx -g "daemon off;"
