FROM	debian:bullseye

RUN	apt-get update && \
	apt-get install -y mariadb-server mariadb-client ca-certificates && \
	rm -rf /var/lib/apt/lists/*

RUN	mkdir -p /run/mysqld && \
	chown -R mysql:mysql /run/mysqld

COPY conf/99-inception.cnf /etc/mysql/mariadb.conf.d/99-inception.cnf
COPY tools/mariadb.sh /usr/local/bin/mariadb.sh

RUN	chmod +x /usr/local/bin/mariadb.sh

EXPOSE	3306

CMD ["/usr/local/bin/mariadb.sh"]
