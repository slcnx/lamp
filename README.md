# lamp
apache mysql php

# php-fpm
- start.sh the scripts on / for starting commands  in container
  - init after hostpath mount container path.
  - start deamon process.

 example:
  docker run --rm -v /etc/localtime:/etc/localtime:ro -v /alidata/www/cakephp/ams/webroot/:/alidata/www/cakephp/ams/webroot/ -v /opt/php7/var:/usr/local/php7.2.25/var/ -p 9009:9000 --name <NAME> <IMAGE>
