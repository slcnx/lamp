#!/bin/bash

create_config() {

echo "--> configdir: /opt/php7/conf.d/"
[ -d /opt/php7/conf.d/ ] || install -dv /opt/php7/conf.d/
[ -f /opt/php7/conf.d/xtra.conf ]
if [ $? -ne 0 ]; then
  echo "生成配置/opt/php7/conf.d/xtra.conf"
  run_user=pxr
  cat > /opt/php7/conf.d/xtra.conf << EOF
;;;;;;;;;;;;;;;;;;;;;
; FPM Configuration ;
;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;
; Global Options ;
;;;;;;;;;;;;;;;;;;

[global]
;pid = run/php-fpm.pid
error_log = log/php-fpm-xtra.log
log_level = warning

emergency_restart_threshold = 30
emergency_restart_interval = 60s
process_control_timeout = 5s
daemonize = yes

;;;;;;;;;;;;;;;;;;;;
; Pool Definitions ;
;;;;;;;;;;;;;;;;;;;;

[www]
listen = 0.0.0.0:9000
listen.backlog = -1
listen.mode = 0666
user = $run_user
group = $run_user
access.log = var/log/www.access.log
slowlog = var/log/www.log.slow
pm = dynamic
pm.max_children = 80
pm.start_servers = 60
pm.max_spare_servers = 80
pm.min_spare_servers = 50
pm.max_requests = 2048
pm.process_idle_timeout = 10s

request_terminate_timeout = 120
request_slowlog_timeout = 0

pm.status_path = /php-fpm_status
rlimit_files = 51200
rlimit_core = 0

catch_workers_output = yes
;env[HOSTNAME] = $HOSTNAME
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp
EOF
fi
# 此处配置名称首字母应当大于w
}




# false --> php:v1
#After the first compilation, the host webroot is mounted, anyway the backend responds with 503 and php-fpm does not report an error
# 使用php目录下dockerfile，即rpm安装php-fpm，php-fpm使用相同的启动参数，并且给php-fpm提供一个配置文件, 报错因为挂载路径中的web主页会引用上级目录
#docker run -d --rm  -v /etc/localtime:/etc/localtime:ro -v  /alidata/www/cakephp/ams/:/alidata/www/cakephp/ams/  -e WEBROOT=/alidata/www/cakephp/ams/ -v /opt/php7/var:/usr/local/php/var/ -v /opt/php7/conf.d/xtra.conf:/usr/local/php/etc/php-fpm.d/xtra.conf -p 9009:9000 ubuntu:php-fpm7.2
#docker run -d --rm  -v /etc/localtime:/etc/localtime:ro -v  /alidata/:/alidata/  -e WEBROOT=/alidata/www/cakephp/ams/ -v /opt/php7/var:/usr/local/php/var/ -v /opt/php7/conf.d/xtra.conf:/usr/local/php/etc/php-fpm.d/xtra.conf -p 9009:9000 ubuntu:php-fpm7.2

## php:v1
# 排错详细见php-rpm-debug.sh

# true
# 下面所有将挂载目录直接指向最顶层
# 但是-e路径指定的容器中会将其chown到php-fpm有权限
#docker run -d --rm  -v /etc/localtime:/etc/localtime:ro -v  /alidata/:/alidata/  -e WEBROOT=/alidata/www/cakephp/ams/ -v /opt/php7/var:/usr/local/php/var/ -v /opt/php7/conf.d/xtra.conf:/usr/local/php/etc/php-fpm.d/xtra.conf -p 9009:9000 ubuntu:php-fpm7.2-plugins




base() {
# true v2 base for pxr
echo "--> docker run -d --rm  -v /etc/localtime:/etc/localtime:ro -v  /alidata/:/alidata/  -e WEBROOT=/alidata/www/cakephp/ams/ -v /opt/php7/var:/usr/local/php/var/ -v /opt/php7/conf.d/xtra.conf:/usr/local/php/etc/php-fpm.d/xtra.conf -p 9009:9000 ubuntu:php-fpm7.2-v2 "
docker run -d --rm  -v /etc/localtime:/etc/localtime:ro -v  /alidata/:/alidata/  -e WEBROOT=/alidata/www/cakephp/ams/ -v /opt/php7/var:/usr/local/php/var/ -v /opt/php7/conf.d/xtra.conf:/usr/local/php/etc/php-fpm.d/xtra.conf -p 9009:9000 ubuntu:php-fpm7.2-v2
echo "
documentroot: /alidata/
expose port: 9008
"
}

plugins() {
# true v2 plugins for pxr
echo '--> docker run -d --rm  -v /etc/localtime:/etc/localtime:ro -v  /alidata/:/alidata/  -e WEBROOT=/alidata/www/cakephp/ams/ -v /opt/php7/var:/usr/local/php/var/ -v /opt/php7/conf.d/xtra.conf:/usr/local/php/etc/php-fpm.d/xtra.conf -p 9009:9000 ubuntu:php-fpm7.2-plugins-v2'
docker run -d --rm  -v /etc/localtime:/etc/localtime:ro -v  /alidata/:/alidata/  -e WEBROOT=/alidata/www/cakephp/ams/ -v /opt/php7/var:/usr/local/php/var/ -v /opt/php7/conf.d/xtra.conf:/usr/local/php/etc/php-fpm.d/xtra.conf -p 9009:9000 ubuntu:php-fpm7.2-plugins-v2
echo "
documentroot: /alidata/
expose port: 9008
"
}


select option in  "启动编译后的镜像" "启动带插件" "exit"; do
  case $option in 
  "启动编译后的镜像")
    create_config
    base;;
  "启动带插件")
    create_config
    plugins;;
  "exit")
    exit;;
  esac
done

