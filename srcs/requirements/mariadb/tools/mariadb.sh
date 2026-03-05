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

# First run: initialize DB + users.
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
  echo "[mariadb] Initializing database ${MYSQL_DATABASE}" >&2
  service mariadb start
  sleep 5

  mariadb -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

  mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
fi

echo "[mariadb] Starting server" >&2
exec mysqld_safe --user=mysql --datadir=/var/lib/mysql --console
