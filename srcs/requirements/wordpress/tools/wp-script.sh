#!/bin/sh
set -eu

# Secrets mounted by Docker (compose `secrets:`) with DB/admin/user passwords
DB_PASS_FILE=/run/secrets/db_password
ADMIN_PASS_FILE=/run/secrets/wp_admin_password
USER_PASS_FILE=/run/secrets/wp_user_password

# Fail fast if any secret is missing/empty.
for f in "$DB_PASS_FILE" "$ADMIN_PASS_FILE" "$USER_PASS_FILE"; do
  [ -s "$f" ] || { echo "[wp] Missing secret $f" >&2; exit 1; }
done

# Pull configuration from env (compose `.env`), with safe defaults for dev
DB_NAME=${MYSQL_DATABASE:-wordpress}
DB_USER=${MYSQL_USER:-wp_user}
DB_HOST=${DB_HOST:-mariadb}
DB_PREFIX=${WP_TABLE_PREFIX:-wp_}
SITE_URL=${WP_URL:-https://localhost}
SITE_TITLE=${WP_TITLE:-Inception}
ADMIN_USER=${WP_ADMIN_USER:-admin}
ADMIN_EMAIL=${WP_ADMIN_EMAIL:-admin@example.com}
WP_USER=${WP_USER:-user}
WP_USER_EMAIL=${WP_USER_EMAIL:-user@example.com}

DB_PASSWORD=$(cat "$DB_PASS_FILE")
ADMIN_PASSWORD=$(cat "$ADMIN_PASS_FILE")
USER_PASSWORD=$(cat "$USER_PASS_FILE")

# Block until DB answers before running WP-CLI
echo "[wp] Waiting for MariaDB at ${DB_HOST}..." >&2
until mysqladmin ping -h "$DB_HOST" --silent; do
  sleep 2
done

# Avoid race with MariaDB init: wait until app credentials can query target DB.
echo "[wp] Waiting for DB credentials to be ready..." >&2
until mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SELECT 1" >/dev/null 2>&1; do
  sleep 2
done

cd /var/www/html

# One-time core download into the mounted volume
if [ ! -f wp-includes/version.php ]; then
  echo "[wp] Downloading WordPress core" >&2
  wp core download --allow-root --quiet
fi

# Create config if missing; keep idempotent
if [ ! -f wp-config.php ]; then
  echo "[wp] Creating wp-config.php" >&2
  wp config create --allow-root \
    --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$DB_PASSWORD" --dbhost="$DB_HOST" \
    --dbprefix="$DB_PREFIX" --skip-check
fi

# Keep config in sync with current env/secrets even if volume already existed.
wp config set DB_NAME "$DB_NAME" --allow-root
wp config set DB_USER "$DB_USER" --allow-root
wp config set DB_PASSWORD "$DB_PASSWORD" --allow-root
wp config set DB_HOST "$DB_HOST" --allow-root
wp config set WP_HOME "$SITE_URL" --allow-root
wp config set WP_SITEURL "$SITE_URL" --allow-root

# Install WP only once
if ! wp core is-installed --allow-root >/dev/null 2>&1; then
  echo "[wp] Installing WordPress" >&2
  wp core install --allow-root \
    --url="$SITE_URL" --title="$SITE_TITLE" \
    --admin_user="$ADMIN_USER" --admin_password="$ADMIN_PASSWORD" --admin_email="$ADMIN_EMAIL"
fi

# Ensure regular user exists
if ! wp user get "$WP_USER" --field=ID --allow-root >/dev/null 2>&1; then
  echo "[wp] Creating user $WP_USER" >&2
  wp user create "$WP_USER" "$WP_USER_EMAIL" --user_pass="$USER_PASSWORD" --role=author --allow-root
fi

chown -R www-data:www-data /var/www/html

echo "[wp] Starting php-fpm" >&2
mkdir -p /run/php
rm -f /run/php/php7.4-fpm.pid
exec php-fpm7.4 -F
