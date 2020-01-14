FROM ubuntu
LABEL maintainer="<slc> 1062670898@qq.com "

ENV PHP_VERSION 7.2.25
ENV LISTEN_PORT 9000
ENV RUN_AS_USER pxr

RUN rm /var/lib/apt/lists/* -vf && \
	apt-get clean && \
	apt-get update
RUN apt-get update && \
apt-get  -y install autoconf build-essential curl libtool \
libssl-dev libcurl4-openssl-dev libxml2-dev libreadline7 \
libreadline-dev libzip-dev libzip4 nginx openssl \
pkg-config zlib1g-dev \
libwebp-dev  libjpeg-turbo8-dev libpng-dev \
wget

RUN useradd -s /sbin/nologin -M ${RUN_AS_USER} && \
	wget  https://www.php.net/distributions/php-${PHP_VERSION}.tar.xz && \
	tar xf php-${PHP_VERSION}.tar.xz && \
	cd php-${PHP_VERSION} && \
	./configure --prefix=/usr/local/php${PHP_VERSION} \
    --enable-mysqlnd \
    --with-pdo-mysql \
    --with-pdo-mysql=mysqlnd \
    --enable-bcmath \
    --enable-fpm \
    --with-fpm-user=${RUN_AS_USER} \
    --with-fpm-group=${RUN_AS_USER} \
    --enable-mbstring \
    --enable-phpdbg \
    --enable-shmop \
    --enable-zip \
    --with-libzip=/usr/lib/x86_64-linux-gnu \
    --with-zlib \
    --with-curl \
    --with-pear \
    --with-openssl \
    --enable-pcntl \
    --with-readline \
    --enable-static \
    --enable-inline-optimization \
    --enable-sockets \
    --enable-wddx \
    --enable-zip \
    --enable-calendar \
    --enable-bcmath \
    --enable-soap \
    --with-zlib \
    --with-iconv \
    --with-gd \
    --with-xmlrpc \
    --enable-mbstring \
    --with-curl \
    --enable-ftp \
    --disable-ipv6 \
    --disable-debug \
    --with-openssl \
    --disable-fileinfo \
    --enable-maintainer-zts \
    --with-png-dir --with-jpeg-dir --with-webp-dir && \
	make &&  \
	make install


# install post
RUN cd php-${PHP_VERSION} && \cp php.ini-production /usr/local/php${PHP_VERSION}/lib/php.ini && \
	cd /usr/local/php${PHP_VERSION}/etc/ && \
	cp php-fpm.conf.default php-fpm.conf && \ 
	cp php-fpm.d/www.conf.default php-fpm.d/www.conf && \
	sed -i 's@listen = .*@listen = 0.0.0.0:${LISTEN_PORT}@' /usr/local/php${PHP_VERSION}/etc/php-fpm.d/www.conf


# parameters
RUN  sed -i '$a post_max_size = 100M\nmemory_limit = 512M\nerror_reporting = E_ERROR | E_PARSE\nupload_max_filesize = 100M\ndate.timezone = PRC\nsession.gc_maxlifetime = 28800' /usr/local/php${PHP_VERSION}/lib/php.ini 


# pdo_oci.so
## oracle
RUN wget https://download.oracle.com/otn_software/linux/instantclient/195000/oracle-instantclient19.5-basic-19.5.0.0.0-1.x86_64.rpm && \
	wget https://download.oracle.com/otn_software/linux/instantclient/195000/oracle-instantclient19.5-sqlplus-19.5.0.0.0-1.x86_64.rpm && \
	wget https://download.oracle.com/otn_software/linux/instantclient/195000/oracle-instantclient19.5-devel-19.5.0.0.0-1.x86_64.rpm && \
	apt-get install -y fakeroot alien libaio1 && \
	fakeroot alien --scripts *.rpm && dpkg -i *.deb && \
	apt-get remove -y alien && rm -fr oracle-instantclient19.5*

ENV ORACLE_HOME="/usr/lib/oracle/19.5/client64/"
ENV LD_LIBRARY_PATH="/usr/lib/oracle/19.5/client64/lib/:$LD_LIBRARY_PATH"

## OCI8
RUN /usr/local/php${PHP_VERSION}/bin/pecl download OCI8 && \
	tar xf oci8-2.2.0.tgz  && \
	cd oci8-2.2.0  && \
	/usr/local/php${PHP_VERSION}/bin/phpize  && \
	./configure --with-oci8=instantclient,/usr/lib/oracle/19.5/client64/lib/ --with-php-config=/usr/local/php${PHP_VERSION}/bin/php-config  && \
	make install && \
	rm -fr oci8-2.2.0.tgz 

## pdo_oci.so
RUN cd /php-${PHP_VERSION}/ext/pdo_oci/  && \
	/usr/local/php${PHP_VERSION}/bin/phpize  && \
	./configure --with-php-config=/usr/local/php${PHP_VERSION}/bin/php-config  --with-pdo-oci=instantclient,/usr/lib/oracle/19.5/client64/lib/  && \
	make  && \
	make install 

# memcache.so
RUN apt-get -y install git  libmemcached-dev  && \
	git clone https://github.com/php-memcached-dev/php-memcached.git  && \
	cd php-memcached  && \
	git checkout php7  && \
	/usr/local/php${PHP_VERSION}/bin/phpize  && \
	./configure --with-php-config=/usr/local/php${PHP_VERSION}/bin/php-config  && \
	make  && \
	make install  && \
	cd .. && rm -rf php-memcached

# redis.so
RUN git clone https://github.com/phpredis/phpredis.git  && \
	 cd phpredis  && \
	/usr/local/php${PHP_VERSION}/bin/phpize  && \
	./configure --with-php-config=/usr/local/php${PHP_VERSION}/bin/php-config  && \
	make  && \
	make install  && \
	cd .. && rm -rf phpredis

# geoip.so
RUN apt-get install -y libgeoip-dev  && \
	/usr/local/php${PHP_VERSION}/bin/pecl install geoip-1.1.1.tgz  

# modudels
RUN echo -e " \n\
extension_dir = $(/usr/local/php${PHP_VERSION}/bin/php-config --extension-dir)\n\
extension="redis.so"\n\
extension="pdo_oci.so"\n\
extension="oci8.so"\n\
extension="memcached.so"\n\
extension="geoip.so"\n\
" >> /usr/local/php${PHP_VERSION}/lib/php.ini

# start script for init log and provide complex start commands.
RUN echo  " \n\
set -x \n\
mkdir -pv /usr/local/php${PHP_VERSION}/var/log \n\
touch /usr/local/php${PHP_VERSION}/var/log/php-fpm.log\n\
/usr/local/php${PHP_VERSION}/sbin/php-fpm --nodaemonize --fpm-config /usr/local/php${PHP_VERSION}/etc/php-fpm.conf\n\
" >> /start.sh && \
chmod +x /start.sh

# clean
RUN cd / && \
	rm -rf  php-${PHP_VERSION} && \
	apt-get remove -y git && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


WORKDIR /
# CMD
CMD  ["/bin/sh","-c","/start.sh"]

