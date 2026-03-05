# DEV_DOC

## Setup From Scratch

### Prerequisites

- Linux VM (project must run in VM for evaluation).
- Docker Engine and Docker Compose plugin (`docker-compose` command available).
- `make`.
- Permission to run Docker commands.

### Repository Layout

- `srcs/docker-compose.yml`: service definitions.
- `srcs/.env`: non-secret environment variables.
- `secrets/*.txt`: secret values (passwords).
- `srcs/requirements/*`: Dockerfiles, configs, entrypoint scripts.

### Initial Setup

1. Create required host data directories:

```bash
mkdir -p /home/$USER/data/mariadb /home/$USER/data/wordpress
```

2. Fill secret files with your own values:

- `secrets/db_root_password.txt`
- `secrets/db_password.txt`
- `secrets/wp_admin_password.txt`
- `secrets/wp_user_password.txt`

3. Configure env values in `srcs/.env`:

- `MYSQL_DATABASE`, `MYSQL_USER`, `DB_HOST`
- `WP_URL`, `WP_TITLE`, `WP_ADMIN_USER`, `WP_ADMIN_EMAIL`
- `WP_USER`, `WP_USER_EMAIL`
- `SERVER_NAME`

### Build And Launch

From project root:

```bash
make up
```

This runs:

- `prepare`: ensures `/home/$USER/data/{mariadb,wordpress}` exists.
- `docker-compose up -d --build` with `srcs/docker-compose.yml` and `srcs/.env`.

### Useful Operations

Start existing containers:

```bash
make start
```

Stop containers:

```bash
make stop
```

Stop and remove containers/network:

```bash
make down
```

Rebuild images:

```bash
make build
```

View status:

```bash
make ps
```

View logs:

```bash
make logs
```

Full reset (remove volumes too):

```bash
make fclean
```

### Containers And Volumes

Services:

- `mariadb` (`mariadb:inception`)
- `wordpress` (`wordpress:inception`)
- `nginx` (`nginx:inception`)

Network:

- `inception` bridge network (explicitly declared in compose)

Persistent data:

- Docker volume `mariadb_data` -> `/home/fkarika/data/mariadb`
- Docker volume `wordpress_data` -> `/home/fkarika/data/wordpress`

Data remains after `make down`, and is removed by `make fclean`.
