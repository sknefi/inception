#!/bin/sh
set -eu

# Small, idempotent MariaDB bootstrapper for the 42 Inception stack.
# It initialises the data directory (if empty), sets the root password from
# Docker secrets, creates the WordPress database/user from env vars, then
# launches mysqld in the foreground for Docker.

ROOT_PWD_FILE=/run/secrets/db_root_password
USER_PWD_FILE=/run/secrets/db_password

# --- Guardrails -------------------------------------------------------------
if [ -z "${MYSQL_DATABASE:-}" ] || [ -z "${MYSQL_USER:-}" ]; then
  echo "[mariadb] MYSQL_DATABASE and MYSQL_USER must be set" >&2
  exit 1
fi

if [ ! -s "$ROOT_PWD_FILE" ] || [ ! -s "$USER_PWD_FILE" ]; then
  echo "[mariadb] Missing /run/secrets/db_root_password or db_password" >&2
  exit 1
fi

DB_ROOT_PASSWORD=$(cat "$ROOT_PWD_FILE")
DB_USER_PASSWORD=$(cat "$USER_PWD_FILE")

# Ensure expected ownership (volume may carry host UID/GID differences).
chown -R mysql:mysql /var/lib/mysql /run/mysqld

# --- Idempotent bootstrap ---------------------------------------------------
# Apply DB/user/grants on every container start so stale volumes are recovered.
echo "[mariadb] Ensuring database/user grants for ${MYSQL_DATABASE}" >&2
TMP_SQL=$(mktemp)
cat > "$TMP_SQL" <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_USER_PASSWORD}';
ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_USER_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
mysqld --user=mysql --datadir=/var/lib/mysql --bootstrap < "$TMP_SQL"
rm -f "$TMP_SQL"

echo "[mariadb] Starting server" >&2
exec mysqld_safe --user=mysql --datadir=/var/lib/mysql --console
