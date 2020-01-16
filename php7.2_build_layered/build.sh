
# 构建v1 
# 在构建过程中修改php-fpm.conf php-fpm.d/www.conf
docker build -t ubuntu:php-fpm7.2 ./ -f Dockerfile1
docker build -t ubuntu:php-fpm7.2-plugins ./ -f Dockerfile-plugin

# 构建v2
# 参考mysql, 我们直接提供一个配置给conf.d/extra.conf
docker build -t ubuntu:php-fpm7.2-v2 ./ -f Dockerfile1-v2
docker build -t ubuntu:php-fpm7.2-plugins-v2 ./ -f Dockerfile-plugin-v2
#
