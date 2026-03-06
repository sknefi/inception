FROM debian:bullseye

RUN apt-get update && \
    apt-get install -y nginx openssl && \
    rm -rf /var/lib/apt/lists/*

RUN rm -f /etc/nginx/sites-enabled/default

COPY conf/nginx.conf /etc/nginx/conf.d/default.conf
COPY tools/nginx.sh /usr/local/bin/nginx.sh

RUN chmod +x /usr/local/bin/nginx.sh

EXPOSE 443

CMD ["/usr/local/bin/nginx.sh"]
