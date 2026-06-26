#!/usr/bin/env bash
set -euo pipefail

# Render injects $PORT (defaults to 10000); Apache must listen on it.
PORT="${PORT:-10000}"
sed -ri "s/^Listen .*/Listen ${PORT}/" /etc/apache2/ports.conf
sed -ri "s/<VirtualHost \*:[0-9]+>/<VirtualHost *:${PORT}>/" /etc/apache2/sites-available/000-default.conf

# Cache config for speed. NOT routes — web.php uses a closure route, which
# would make `route:cache` fail.
php artisan config:cache

# Apply migrations for the app tables (auth lives in Supabase, not here).
php artisan migrate --force

exec apache2-foreground
