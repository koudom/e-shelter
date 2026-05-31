#!/bin/sh
set -e

# Set PORT from Cloud Run environment (default 8080)
NGINX_PORT=${PORT:-8080}
export NGINX_PORT

# Substitute NGINX_PORT in nginx template
envsubst '$NGINX_PORT' < /etc/nginx/templates/default.conf.template > /etc/nginx/http.d/default.conf

# Create runtime directories
mkdir -p /var/run /var/log/nginx /var/log/supervisor

# Ensure storage and bootstrap/cache are writable
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Run Laravel optimization commands
php -d variables_order=EGPCS /var/www/html/artisan config:cache --no-interaction
php -d variables_order=EGPCS /var/www/html/artisan route:cache --no-interaction
php -d variables_order=EGPCS /var/www/html/artisan view:cache --no-interaction

# Start supervisord (PID 1)
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
