#!/bin/sh
set -eu

SSL_DIR=/etc/nginx/ssl
CRT=$SSL_DIR/inception.crt
KEY=$SSL_DIR/inception.key
SERVER_NAME=${SERVER_NAME:-fkarika.42.fr}

mkdir -p "$SSL_DIR"

# Create a self-signed cert on first start
if [ ! -s "$CRT" ] || [ ! -s "$KEY" ]; then
  echo "[nginx] Generating self-signed cert for $SERVER_NAME" >&2
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$KEY" -out "$CRT" \
    -subj "/C=CZ/ST=Prague/L=Prague/O=42/OU=Inception/CN=$SERVER_NAME"
fi

# Run nginx in foreground so Docker keeps container alive
echo "[nginx] Starting" >&2
exec nginx -g "daemon off;"
