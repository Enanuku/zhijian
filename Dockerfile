# PHP\Python\NodeJS
# 
# Version:1.0.0

FROM centos:7
MAINTAINER Qingfeng Dubu <1135326346@qq.com>

ENV REFRESHED_AT 2015-06-05

RUN yum -y update; yum clean all

# install the epel

RUN yum -y install epel-release; yum clean all

RUN rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm

RUN yum -y install git gcc make gcc libtool; yum clean all

# set timezone to PRC
RUN mv /etc/localtime /etc/localtime.bak && \
    ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

######################  supervisor ####################
# Install supervisor

RUN yum install -y python-setuptools; yum clean all
RUN easy_install pip
RUN pip install supervisor

######################## nginx ########################
# Install nginx 

ADD nginx.repo /etc/yum.repos.d/nginx.repo
RUN yum -y install nginx; yum clean all

########################  php  ########################
# Install PHP

RUN yum -y --enablerepo=remi,remi-php56 --skip-broken install php-fpm php-common php-cli php-pdo php-mysql php-gd php-imap php-ldap php-odbc php-opcache php-pear php-xml php-devel php-xmlrpc php-mbstring php-mcrypt php-bcmath php-mhash libmcrypt pcre-devel; yum clean all

RUN git clone --depth=1 git://github.com/phalcon/cphalcon.git /root/phalcon
RUN cd /root/phalcon/build && ./install
RUN echo extension=/usr/lib64/php/modules/phalcon.so >> /etc/php.d/phalcon.ini

###############  virtualenv Django ####################
# Install virtualenv

RUN yum -y group install "Development Tools"; yum clean all
RUN yum -y install python-virtualenv; yum clean all

RUN mkdir /src
ADD requirements.txt /src/requirements.txt

# Install Django and web.py

RUN cd /src; pip install -r requirements.txt

########################  mysql  ########################
# Install mysql

# RUN yum -y install mysql mysql-server; yum clean all
# RUN echo "NETWORKING=yes" > /etc/sysconfig/network

# start mysqld to create initial tables

# RUN service mysqld start

########################  mariadb  ########################
# Install mariadb
RUN yum install mariadb-server mariadb -y; yum clean all

# Initialize Database Directory
RUN /usr/libexec/mariadb-prepare-db-dir

# Enable MySQL/MariaDB
RUN systemctl enable mariadb.service

######################  composer  ########################
# Set environmental variables

ENV COMPOSER_HOME /root/composer

# Install Composer

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Display version information

RUN php --version && \
  composer --version

####################  nodejs and npm  ######################
# install the nodejs and npm

RUN yum -y install \
      nodejs \
      npm ; \
    yum -y clean all

RUN npm install express serve-favicon config morgan async node-minify \
    handlebars lodash walk pm2

########################  mongodb  ##########################
# Install the mongodb

ADD mongodb.repo /etc/yum.repos.d/mongodb.repo
RUN yum -y --skip-broken install mongodb-server mongodb-org; yum clean all
RUN mkdir -p /data/db
RUN pecl install mongo
RUN echo extension=mongo.so >> /etc/php.d/mongo.ini

####################################################
# Add the configuration file of the nginx

ADD nginx.conf /etc/nginx/nginx.conf
ADD default.conf /etc/nginx/conf.d/default.conf

# Add the configuration file of the Supervisor

ADD supervisord.conf /etc/

# Add the file

ADD index.php /var/www/index.php
ADD index.py /src/index.py
ADD app.js /src/app.js

# Set the port to 80,8080,1337,27017,3306

EXPOSE 80 8080 27017 1337 3306

# Executing supervisord

CMD ["supervisord", "-n"]