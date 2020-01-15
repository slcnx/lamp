# 前言
 在我尝试先进入容器(docker run -it --rm ubuntu /bin/bash)执行完所有操作, nginx只是测试了phpinfo()页面, 反代至其上, 正常。我便以为正常了，并记录下所有容器中的命令历史。写成一个dockerfile(../php7.2.25/) 

 有问题, 反正就是可以访问phpinfo, 就是不能正常访问网页。

 排错思路：
  以为是权限原因, 但是已经给网页源文件chown pxr.pxr -R .
    不行
 
   看来只有推倒重来
    1）进入容器(docker run -it --rm ubuntu -v /opt/myphpsrc:/usr/share/nginx/html -p 9002:80 -p 9008:9000 /bin/bash), agp-get install -y nginx php-fpm php-mysql

      修改pool.d/www.conf 
        listen = 0.0.0.0:9000


    2）配置nginx让用户请求php反代至本机的php-fpm服务
      /etc/conf.d/lamp.conf
  server {
    server_name myapp.mykernel.cn;
    listen 80;
    root /usr/share/nginx/html;

    location / {
      index index.html index.htm; 
    }
    location ~* \.php$ {
      fastcgi_pass myapp.mykernel.cn:9008;
      fastcgi_index index.php;
      fastcgi_param SCRIPT_FILENAME /usr/share/nginx/html$fastcgi_script_name;
      include fastcgi_params;
      fastcgi_param PATH_INFO $fastcgi_path_info;
    }
  }

    因为我们用-p映射宿主机9008到内部9000，所以直接写宿主机及映射PORT即可。要求：内部监听在0.0.0.0:9000 


    3）启动
      启动nginx, php-fpm
        nginx 
        php-fpm7.2

   
    4）提供宿主机/opt/myphpsrc/wordpress
      建立mysql账号


    5）网页访问9002正常

      容器中nginx --> php 正常




  # 检测另一个容器nginx --> php
    启动另一个容器(../nginx/ 构建后)

    docker build -t nginx_php-fpm:v2 ./ ; docker run  --rm -v /opt/nginx/html:/usr/share/nginx/html/ -p 8083:80 nginx_php-fpm:v2

    网页访问 8083 正常


  # 检测另一个容器nginx --> 容器中的编译php
    入容器(docker run -it --rm ubuntu -v /opt/myphpsrc:/usr/share/nginx/html -p 9002:80 -p 9008:9000 /bin/bash)

  export PHP_VERSION=7.2.25
  export LISTEN_PORT=9000
  export RUN_AS_USER=www

   apt-get update && \
  apt-get  -y install autoconf build-essential curl libtool \
  libssl-dev libcurl4-openssl-dev libxml2-dev libreadline7 \
  libreadline-dev libzip-dev libzip4 nginx openssl \
  pkg-config zlib1g-dev \
  libwebp-dev  libjpeg-turbo8-dev libpng-dev \
  wget && \
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
      make install && \
  cp php.ini-production /usr/local/php${PHP_VERSION}/lib/php.ini && \
  cd /usr/local/php${PHP_VERSION}/etc/ && \
  cp php-fpm.conf.default php-fpm.conf && \ 
  cp php-fpm.d/www.conf.default php-fpm.d/www.conf && \
  sed -i 's@listen = .*@listen = 0.0.0.0:${LISTEN_PORT}@' /usr/local/php${PHP_VERSION}/etc/php-fpm.d/www.conf
    

      启动php-fpm
        /usr/local/php${PHP_VERSION}/sbin/php-fpm


      网页测试
    
        失败，访问phpinfo正常，其它php失败



    结论：
      如果一定弄完所有指令在一个镜像, 出错不方便排查，是基础构建层问题，还是插件问题。


    编译参数复制少了 --with-mysqli=mysqlnd 



  
  
# php-fpm 和plugin 拆分
## 1. 构建基础编译后的层
 cd php7.2_build_layered 
cat Dockerfile1 | docker build -t ubuntu:php-fpm7.2 - || docker build -t ubuntu:php-fpm7.2 -f Dockerfile1 ./


  访问过程：php 动态脚本在php-server根文档路径下访问。/opt/myphpsrc/
          不是php脚本在nginx根文档路径下访问。 /opt/nginx/html/
      
        当请求静态资源在nginx当前服务器找。
        当请求动态在php
        当请求目录重写


  启动php-fpm命令
    docker run -it --rm  -v /etc/localtime:/etc/localtime:ro -v /opt/myphpsrc:/opt/myphpsrc -e WEBROOT=/opt/myphpsrc/ -v /opt/php7/var:/usr/local/php7.2.25/var/ -p 9008:9000 ubuntu:php-fpm7.2

  构建nginx命令 
    cd nginx
    docker build -t  nginx_php-fpm:v5 ./
    启动 docker run --rm -v /opt/nginx/html/:/usr/share/nginx/html/ -p 8083:80 nginx_php-fpm:v5


## 2. 构建插件层
 cd php7.2_build_layered 
 # docker build -t ubuntu:php-fpm7.2-plugins -f Dockerfile-plugin ./

  启动php-fpm命令
    docker run -it --rm  -v /etc/localtime:/etc/localtime:ro -v /opt/myphpsrc:/opt/myphpsrc -e WEBROOT=/opt/myphpsrc/ -v /opt/php7/var:/usr/local/php7.2.25/var/ -p 9008:9000 ubuntu:php-fpm7.2-plugins

  构建nginx命令 
    cd nginx
    docker build -t  nginx_php-fpm:v5 ./
    启动 docker run --rm -v /opt/nginx/html/:/usr/share/nginx/html/ -p 8083:80 nginx_php-fpm:v5


## 3.网页访问

  
