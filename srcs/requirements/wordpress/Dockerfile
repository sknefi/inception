FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    wget \
    php7.4 \
    php7.4-fpm \
    php7.4-mysql \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf
COPY tools/wp-script.sh /usr/local/bin/wp-script.sh

RUN chmod +x /usr/local/bin/wp-script.sh

WORKDIR /var/www/html
EXPOSE 9000

CMD ["/usr/local/bin/wp-script.sh"]
