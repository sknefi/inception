*This project has been created as part of the 42 curriculum by fkarika.*

# Inception

## Description

Inception is a system administration project focused on containerized infrastructure with Docker Compose.
The goal is to deploy a small production-like stack in a VM, split into isolated services:

- `nginx` as the only public entrypoint on port `443`
- `wordpress` with PHP-FPM
- `mariadb` as the database backend

The stack uses environment variables from `srcs/.env`, Docker secrets from `secrets/*.txt`, a dedicated Docker network, and persistent Docker volumes.

## Project Description

This project uses Docker to package each service with its own Dockerfile and runtime configuration.
The source files are organized under `srcs/requirements/{nginx,mariadb,wordpress}` with:

- `Dockerfile` for image build logic
- `conf/` for service configuration
- `tools/` for entrypoint/init scripts

Main design choices:

- one process role per container
- TLS termination in nginx only
- WordPress and MariaDB private on an internal bridge network
- persistent data storage outside containers under `/home/<login>/data`

### Virtual Machines vs Docker

- Virtual machine: emulates full OS + kernel, heavier and slower to start
- Docker container: shares host kernel, lightweight, faster startup, easier reproducibility
- In this project: VM is the required host boundary, Docker provides service isolation inside it

![VM vs Docker](https://miro.medium.com/1*KtazvJZ-IX6aoq3jCjD5tA.png)

### Secrets vs Environment Variables

- Environment variables are convenient for non-sensitive configuration
- Secrets are better for passwords and confidential values
- In this project: credentials are read from Docker secrets mounted in `/run/secrets/*`

### Docker Network vs Host Network

- Bridge network isolates service communication and gives internal DNS by service name
- Host network removes isolation and is forbidden by subject constraints
- In this project: services communicate on the `inception` bridge network

### Docker Volumes vs Bind Mounts

- Docker volumes are managed by Docker and are safer for persistent container data
- Bind mounts map explicit host paths directly
- In this project: named volumes are used for persistence and mapped to `/home/<login>/data/*`

## Instructions

Prerequisites:

- Linux VM
- Docker and Docker Compose (`docker-compose`)
- `make`

Set local DNS mapping on the machine running the browser:

```bash
echo "127.0.0.1 fkarika.42.fr" | sudo tee -a /etc/hosts
```

Run from repository root:

```bash
make up
```

Useful commands:

```bash
make ps
make logs
make down
make fclean
```

Access:

- Website: `https://fkarika.42.fr`
- Admin panel: `https://fkarika.42.fr/wp-admin`

Additional docs:

- User guide: `USER_DOC.md`
- Developer guide: `DEV_DOC.md`

## Resources

References:

- Docker documentation: https://docs.docker.com/
- Docker Compose specification: https://docs.docker.com/compose/compose-file/
- NGINX documentation: https://nginx.org/en/docs/
- MariaDB documentation: https://mariadb.com/kb/en/documentation/
- WordPress documentation: https://wordpress.org/documentation/
- WP-CLI documentation: https://developer.wordpress.org/cli/commands/
- OpenSSL manual pages (`man openssl`, `man req`)

AI usage:

- AI was used to review configuration consistency and debug container startup issues.
- AI helped generate and refine shell entrypoint scripts for MariaDB, WordPress, and nginx.
- AI was used to improve project documentation (`README.md`, `USER_DOC.md`, `DEV_DOC.md`).
- Final validation, integration tests, and acceptance decisions were done manually in the VM.
