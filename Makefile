.RECIPEPREFIX := >

COMPOSE_FILE = srcs/docker-compose.yml
ENV_FILE = srcs/.env
COMPOSE = docker-compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE)
DATA_DIR = /home/$(USER)/data

.PHONY: all up down build start stop logs ps re clean fclean prepare

all: up

prepare:
>mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress

up: prepare
>$(COMPOSE) up -d --build

down:
>$(COMPOSE) down

build:
>$(COMPOSE) build

start:
>$(COMPOSE) start

stop:
>$(COMPOSE) stop

logs:
>$(COMPOSE) logs -f

ps:
>$(COMPOSE) ps

clean: down

fclean:
>$(COMPOSE) down -v --remove-orphans

re: down up
