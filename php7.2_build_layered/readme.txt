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
    docker run -it --rm  -v /etc/localtime:/etc/localtime:ro -v /opt/nginx/html/:/opt/myphpsrc -e WEBROOT=/opt/myphpsrc/ -v /opt/php7/var:/usr/local/php7.2.25/var/ -p 9008:9000 ubuntu:php-fpm7.2

  构建nginx命令 
    cd nginx
    docker build -t  nginx_php-fpm:v5 ./
    启动 docker run --rm -v /opt/nginx/html/:/usr/share/nginx/html/ -p 8083:80 nginx_php-fpm:v5


## 2. 构建插件层
 cd php7.2_build_layered 
 # docker build -t ubuntu:php-fpm7.2-plugins -f Dockerfile-plugin ./

  启动php-fpm命令
    docker run -it --rm  -v /etc/localtime:/etc/localtime:ro -v /opt/nginx/html/:/opt/myphpsrc -e WEBROOT=/opt/myphpsrc/ -v /opt/php7/var:/usr/local/php7.2.25/var/ -p 9008:9000 ubuntu:php-fpm7.2-plugins

  构建nginx命令 
    cd nginx
    docker build -t  nginx_php-fpm:v5 ./
    启动 docker run --rm -v /opt/nginx/html/:/usr/share/nginx/html/ -p 8083:80 nginx_php-fpm:v5

## 3.提供phpsrc
  如果我们按照前2步执行肯定/opt/已经存在这些目录了
  [root@alyy php7.2_build_layered]# tree -L 1 /opt/nginx/html/ /opt/myphpsrc/ /opt/php7/var
  /opt/nginx/html/
  /opt/myphpsrc/
  /opt/php7/var
  `-- log

  在/opt/nginx/html/提供wordpress.
  [root@alyy html]# tar xf wordpress-5.3.2.tar.gz 
  [root@alyy html]# mv wordpress/* ./
  

## 宿主机代理
 [root@alyy conf.d]# cat wordpress.conf 
server {
    listen 80;
    server_name lc.mykernel.cn; # 服务器域名和 IP 地址
    location / {
        proxy_pass http://127.0.1:8083/; # 
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_redirect off;
    }
}

  nginx -t
nginx -s reload
 
## 修改nginx 构建镜像让server_name同代理的域名
## 3.网页访问
  插件验证页面 http://myapp.mykernel.cn:8083/phpinfo.php
    <?php
    phpinfo():
  ?>
  主页即代理名称 lc.mykernel.cn

  
### 总结：docker构建后并后台运行
  nginx:
    cd nginx
    docker build -t  nginx:php-fpm7.2 ./
    docker run --rm -d -v /opt/nginx/html/:/usr/share/nginx/html/ -p 8083:80  nginx:php-fpm7.2


        comments:
            -v /opt/nginx/html/:/usr/share/nginx/html/ nginx接收到请求后，访问静态资源文件所在目录
            -p 8083:80 映射容器中的端口


  php-fpm: 
    1）没有插件
     cd php7.2_build_layered
     cat Dockerfile1 | docker build -t ubuntu:php-fpm7.2 - || docker build -t ubuntu:php-fpm7.2 -f Dockerfile1 ./
    docker run -d --rm  -v /etc/localtime:/etc/localtime:ro -v /opt/nginx/html/:/opt/myphpsrc -e WEBROOT=/opt/myphpsrc/ -v /opt/php7/var:/usr/local/php/var/ -p 9008:9000 ubuntu:php-fpm7.2 

        comments: 
            -v /opt/nginx/html/:/opt/myphpsrc     之前我尝试过/opt/nginx/html/目录指定在另一个位置，看起来真的动态和静态资源分离在不同的路径下(/opt/nginx/html, /opt/myphpsrc)，nginx location也分离了，但是出现一个问题，静态资源目录下删除php文件后, 网站访问各种403. 
                                                  现在这种写法就相当于nginx的静态资源和php-fpm的脚本文件在一个位置只是我们使用了nginx location, 分离不同url访问相同的目录。
                                                    当我们上传博客或图片时，这样如果按前面说的在不同路径下，传递到php-fpm的动态脚本那个目录下了，nginx location静态在另一个目录，上传后看不见资源。
                                                    但是我们放在一起时, 其实就一个目录，不存在这个问题。

            -v /etc/localtime:/etc/localtime:ro 表示容器时区和宿主机一样 eg. 同样是CST
            -v -v /opt/nginx/html/:/opt/myphpsrc 宿主机动态资源位置:容器中位置。    注意：nginx反代至php-fpm指定的路径是“容器中的动态资源位置”（即:后面的路径）
            -e WEBROOT=/opt/myphpsrc/ 是start.sh脚本在启动时，将所有php资源权限修改为php-fpm运行用户的权限, 因为运行php脚本会在目录下创建文件。
            -v /opt/php7/var:/usr/local/php7.2.25/var/ 输出php-7.2.25编译目录中的var目录，当挂载后var目录中的log目录会消失(如果宿主机挂载目录中没有log的话。), 为了避免因为挂载后目录中的可变文件消失，在start.sh脚本中会在/usr/local/php7.2.25/var/目录中创建log目录及touch日志文件. 注意：虽然我们利用脚本在容器中生成新文件，但是新文件的路径是在挂载后生成的，--rm启动后，kill掉容器后，/opt/php7/var下包括所有新生成的文件。
            -p 9008:9000 暴露容器中的端口，注意：踩坑：因为里面默认监听在127.0.0.1，nginx proxy过去会返回503, 所以在Dockerfile中构建php-fpm时, 会修改listen在0.0.0.0; 


    2）有插件
       cd php7.2_build_layered
       cat Dockerfile1 | docker build -t ubuntu:php-fpm7.2-plugins - || docker build -t ubuntu:php-fpm7.2-plugins -f Dockerfile1 ./
       docker run -d --rm  -v /etc/localtime:/etc/localtime:ro -v /opt/nginx/html/:/opt/myphpsrc -e WEBROOT=/opt/myphpsrc/ -v /opt/php7/var:/usr/local/php/var/ -p 9008:9000 ubuntu:php-fpm7.2-plugins

  
  以后修改配置时，或增加功能时, 进入构建目录, 
    1）基于Dockerfile文件, 直接添加在文件后
    2）基于Dockerfile文件, 先构建出基础镜像，第二个Dockerfile FROM 构建的镜像,


  以上这样配置，通过容器nginx的端口8083可以访问。 为了方便的域名访问，可以在宿主机上反向代理至容器。

 
  补充：如果你启动时需要换路径或端口，应当明确
    1）有关联性的配置
      docker run nginx 
          -v /opt/nginx/html/:/usr/share/nginx/html/ 前面路径同php-fpm前面路径
      docker run ubuntu:php-fpm
          -v /opt/nginx/html/:/opt/myphpsrc -e WEBROOT=/opt/myphpsrc/ 前面路径同nginx前面路径, WEBROOT同后面路径
          -p 9008:9000  更改前面的端口需要重新制作nginx， Dockerfile中引用的配置文件中proxy_pass facgi指定的端口需要和前面一致。               修改后面的端口需要重新制作php-fpm 


    2）无关联性配置

      docker run nginx 
         -p 9008:9000 前面端口随便, 但是宿主机nginx反向代理时要代理至前面的端口9008
      docker run ubuntu:php-fpm
        -v /opt/php7/var:/usr/local/php/var/ 前面路径随意，后面编译时固定位置
  

        

   
  
     
      
