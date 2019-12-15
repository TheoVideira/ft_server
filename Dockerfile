FROM debian:buster

LABEL maintainer="Théo Videira (tvideira@student.42.fr)"

ARG AUTOINDEX=on
ARG VER_PHPMA=4.9.2

RUN apt-get update		&& \
	apt-get upgrade -y	&& \
	apt-get install -y wget procps net-tools

#Install nginx
RUN apt-get install -y nginx

#Install mariadb
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server

#Install php
RUN apt-get install -y	php php-fpm php-mysqli php-pear php-mbstring \
						php-gettext php-common php-phpseclib php-mysql

#Install phpmyadmin
RUN cd /tmp 												&& \
	wget https://files.phpmyadmin.net/phpMyAdmin/${VER_PHPMA}/phpMyAdmin-${VER_PHPMA}-all-languages.tar.gz && \
	tar -xvf phpMyAdmin-${VER_PHPMA}-all-languages.tar.gz 	&& \
	rm phpMyAdmin*.tar.gz 									&& \
	mv phpMyAdmin* /usr/share/phpmyadmin 					&& \
	mkdir -p /var/lib/phpmyadmin 							&& \
	mkdir -p /var/lib/phpmyadmin/tmp 						&& \
	ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin 	&& \
	service mysql start 									&& \
	mysql < /usr/share/phpmyadmin/sql/create_tables.sql

#Install wordpress
RUN cd /tmp 											&& \
	wget https://fr.wordpress.org/latest-fr_FR.tar.gz 	&& \
	tar -xvf latest-fr_FR.tar.gz 						&& \
	mv wordpress /var/www/html/wordpress
	
#Setup nginx
COPY srcs/nginx.conf 		/etc/nginx/nginx.conf

#Setup phpmyadmin
COPY srcs/phpmyadmin-config.php /usr/share/phpmyadmin/config.inc.php

#Setup wordpress
COPY srcs/wp-config.php /var/www/html/wordpress

#SOME PASSWORD IN CLEAR VERY NICE
RUN service mysql start 							&& \
	mysql -u root -e "CREATE DATABASE wordpress_db" && \
	mysql -u root -e "GRANT ALL ON wordpress_db.* TO 'wordpress_user'@'localhost' IDENTIFIED BY 'moncorpsestenpleinecroissance' WITH GRANT OPTION" && \
	mysql -u root -e "GRANT ALL ON phpmyadmin.* TO 'pma'@'localhost' IDENTIFIED BY 'ilmefautdeleau'" && \
	mysql -u root -e "GRANT ALL ON *.* TO 'bob'@'localhost' IDENTIFIED BY '123'"

#RUN sed -i "s/autoindex off/autoindex ${AUTOINDEX}/" /etc/nginx/nginx.conf

CMD service nginx start			&& \
	service mysql start 		&& \
	service php7.3-fpm start	&& \
	tail -f /dev/null


EXPOSE 80 443