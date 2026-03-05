#!/bin/sh
set -eu

# Docker secrets mounted by compose; keeps passwords out of image/env
ROOT_PWD_FILE=/run/secrets/db_root_password
USER_PWD_FILE=/run/secrets/db_password

# Required runtime configuration comes from `.env`
if [ -z "${MYSQL_DATABASE:-}" ] || [ -z "${MYSQL_USER:-}" ]; then
  echo "[mariadb] MYSQL_DATABASE and MYSQL_USER must be set" >&2
  exit 1
fi

# Fail fast if secrets are missing or empty
if [ ! -s "$ROOT_PWD_FILE" ] || [ ! -s "$USER_PWD_FILE" ]; then
  echo "[mariadb] Missing /run/secrets/db_root_password or db_password" >&2
  exit 1
fi

MYSQL_ROOT_PASSWORD=$(cat "$ROOT_PWD_FILE")
MYSQL_PASSWORD=$(cat "$USER_PWD_FILE")

# Ensure runtime directories and data files have correct ownership
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# Start MariaDB once in background to apply idempotent SQL setup
echo "[mariadb] Preparing database/users" >&2
service mariadb start
sleep 5

ROOT_AUTH_MODE=""
# Support both first boot (root without password) and restarted boot (root with password)
if mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; then
  ROOT_AUTH_MODE="password"
elif mariadb -u root -e "SELECT 1" >/dev/null 2>&1; then
  ROOT_AUTH_MODE="no_password"
else
  echo "[mariadb] Cannot authenticate as root (with or without password)" >&2
  exit 1
fi

# Small helper to execute SQL with the correct root auth mode
run_sql() {
  if [ "$ROOT_AUTH_MODE" = "password" ]; then
    mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "$1"
  else
    mariadb -u root -e "$1"
  fi
}

# On first run, set the root password before running privileged SQL
if [ "$ROOT_AUTH_MODE" = "no_password" ]; then
  run_sql "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"
  ROOT_AUTH_MODE="password"
fi

# Idempotent setup: safe to run on every container start
run_sql "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"
run_sql "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
run_sql "ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
run_sql "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';"
run_sql "FLUSH PRIVILEGES;"

# Stop background bootstrap instance; then launch main foreground process (PID 1)
mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown

echo "[mariadb] Starting server" >&2
exec mysqld_safe --user=mysql --datadir=/var/lib/mysql --console
