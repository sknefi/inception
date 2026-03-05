FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    wget \
    curl \
    ca-certificates \
    php7.4 \
    php7.4-cli \
    php7.4-fpm \
    php7.4-mysql \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp

COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf
COPY tools/wp-script.sh /usr/local/bin/wp-script.sh

RUN chmod +x /usr/local/bin/wp-script.sh

WORKDIR /var/www/html
EXPOSE 9000

CMD ["/usr/local/bin/wp-script.sh"]
