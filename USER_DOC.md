# USER_DOC

## What This Stack Provides

This project runs 3 services:

- `nginx`: HTTPS entrypoint on port `443` with TLS.
- `wordpress`: WordPress with PHP-FPM.
- `mariadb`: database for WordPress.

Data is persistent through 2 Docker named volumes mapped to host folders:

- `/home/<login>/data/mariadb`
- `/home/<login>/data/wordpress`

## Start And Stop

From project root:

```bash
make up
```

Stop containers:

```bash
make down
```

Stop and remove volumes (full reset):

```bash
make fclean
```

## Access The Website And Admin Panel

Set domain resolution on the machine where your browser runs:

```bash
echo "127.0.0.1 fkarika.42.fr" | sudo tee -a /etc/hosts
```

If browser runs on host and Docker runs in a VM, replace `127.0.0.1` with VM IP.

Then open:

- Website: `https://fkarika.42.fr`
- Admin: `https://fkarika.42.fr/wp-admin`

Note: certificate is self-signed, browser security warning is expected.

## Credentials Location And Management

Environment values are in:

- `srcs/.env`

Secret passwords are in:

- `secrets/db_root_password.txt`
- `secrets/db_password.txt`
- `secrets/wp_admin_password.txt`
- `secrets/wp_user_password.txt`

After changing credentials, rebuild and restart:

```bash
make down
make up
```

## Health Checks

Check containers:

```bash
make ps
```

Watch logs:

```bash
make logs
```

Quick HTTP check:

```bash
curl -kI https://fkarika.42.fr
```

Expected result includes `HTTP/1.1 200 OK`.
