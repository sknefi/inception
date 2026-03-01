FROM	debian:bullseye

RUN	apt-get update && \
	apt-get install -y mariadb-server mariadb-client ca-certificates && \
	rm -rf /var/lib/apt/lists/*

RUN	mkdir -p /run/mysqld && \
	chown -R mysql:mysql /run/mysqld
