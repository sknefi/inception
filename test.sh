#!/bin/bash

docker run --rm -it --name mariadb \
  --env-file srcs/.env \
  -v "$PWD/secrets/db_root_password.txt":/run/secrets/db_root_password.txt:ro \
  -v "$PWD/secrets/db_password.txt":/run/secrets/db_password.txt:ro \
  -v /home/fkarika/data/mariadb:/var/lib/mysql \
  -p 3306:3306 \
  -d \
  mariadb:test
