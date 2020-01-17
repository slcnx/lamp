# 此处构建专门为wordpress 上传超时设定的 php.ini多一个参数
docker build -t ubuntu:php-fpm7.2-v3 ./ -f Dockerfile1-v3-wppostvideo
docker build -t ubuntu:php-fpm7.2-plugins-v3 ./ -f Dockerfile-plugin-v3-wppostvideo
