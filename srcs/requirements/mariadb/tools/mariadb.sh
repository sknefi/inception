#!/bin/sh
set -eu

ROOT_PWD_FILE=/run/secrets/db_root_password
USER_PWD_FILE=/run/secrets/db_password

if [ -z "${MYSQL_DATABASE:-}" ] || [ -z "${MYSQL_USER:-}" ]; then
  echo "[mariadb] MYSQL_DATABASE and MYSQL_USER must be set" >&2
  exit 1
fi

if [ ! -s "$ROOT_PWD_FILE" ] || [ ! -s "$USER_PWD_FILE" ]; then
  echo "[mariadb] Missing /run/secrets/db_root_password or db_password" >&2
  exit 1
fi

MYSQL_ROOT_PASSWORD=$(cat "$ROOT_PWD_FILE")
MYSQL_PASSWORD=$(cat "$USER_PWD_FILE")

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

echo "[mariadb] Preparing database/users" >&2
service mariadb start
sleep 5

ROOT_AUTH_MODE=""
if mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; then
  ROOT_AUTH_MODE="password"
elif mariadb -u root -e "SELECT 1" >/dev/null 2>&1; then
  ROOT_AUTH_MODE="no_password"
else
  echo "[mariadb] Cannot authenticate as root (with or without password)" >&2
  exit 1
fi

run_sql() {
  if [ "$ROOT_AUTH_MODE" = "password" ]; then
    mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "$1"
  else
    mariadb -u root -e "$1"
  fi
}

if [ "$ROOT_AUTH_MODE" = "no_password" ]; then
  run_sql "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"
  ROOT_AUTH_MODE="password"
fi

run_sql "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"
run_sql "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
run_sql "ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
run_sql "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';"
run_sql "FLUSH PRIVILEGES;"

mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown

echo "[mariadb] Starting server" >&2
exec mysqld_safe --user=mysql --datadir=/var/lib/mysql --console
