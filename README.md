# lamp
apache mysql php

# php-fpm
- start.sh the scripts on / for starting commands  in container
  - init after hostpath mount container path.
  - start deamon process.

# docker构建后并后台运行
后台运行--rm并不影响停止时清空数据，因为可变的数据已经输出来了, 在输出目录下不会因为删容器， 数据丢失。
但是我们仍需要进行备份：网站数据(上传的静态文件)；mysql数据
  ## nginx:
    cd nginx
    docker build -t  nginx:php-fpm7.2 ./
    docker run --rm -d -v /opt/nginx/html/:/usr/share/nginx/html/ -p 8083:80  nginx:php-fpm7.2


        comments:
            -v /opt/nginx/html/:/usr/share/nginx/html/ nginx接收到请求后，访问静态资源文件所在目录
            -p 8083:80 映射容器中的端口


  ## php-fpm: 
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

  
## 以后修改配置时，或增加功能时, 进入构建目录, 

- 基于Dockerfile文件, 直接添加在文件后
- 基于Dockerfile文件, 先构建出基础镜像，第二个Dockerfile FROM 构建的镜像,

## 以上这样配置，通过容器nginx的端口8083可以访问。 为了方便的域名访问，可以在宿主机上反向代理至容器。

## 如果你启动时需要换路径或端口，应当明确

- 有关联性的配置
```
  docker run nginx 
      -v /opt/nginx/html/:/usr/share/nginx/html/ 前面路径同php-fpm前面路径
  docker run ubuntu:php-fpm
      -v /opt/nginx/html/:/opt/myphpsrc -e WEBROOT=/opt/myphpsrc/ 前面路径同nginx前面路径, WEBROOT同后面路径
      -p 9008:9000  更改前面的端口需要重新制作nginx， Dockerfile中引用的配置文件中proxy_pass facgi指定的端口需要和前面一致。               修改后面的端口需要重新制作php-fpm 
```

- 无关联性配置
```
  docker run nginx 
     -p 9008:9000 前面端口随便, 但是宿主机nginx反向代理时要代理至前面的端口9008
  docker run ubuntu:php-fpm
    -v /opt/php7/var:/usr/local/php/var/ 前面路径随意，后面编译时固定位置
```

        
