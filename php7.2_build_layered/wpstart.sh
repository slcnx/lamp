#!/bin/bash
create_config() {
echo "--> configdir: /opt/php7/conf.d/"
[ -d /opt/php7/conf.d/ ] || install -dv /opt/php7/conf.d/
[ -f /opt/php7/conf.d/xtra.conf ]
if [ $? -ne 0 ]; then
  echo "生成配置 /opt/php7/conf.d/xtra.conf"
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
user = ${run_user}
group = ${run_user}


access.log = var/log/www.access.log
slowlog = var/log/www.log.slow
pm = dynamic
pm.max_children = 20
pm.start_servers = 10
pm.max_spare_servers = 20
pm.min_spare_servers = 10
pm.max_requests = 2048
pm.process_idle_timeout = 10s

request_terminate_timeout = 600
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

base() {
# true v2 base for wordpress
docker run -d --rm  -v /etc/localtime:/etc/localtime:ro -v /opt/nginx/html/:/opt/myphpsrc -e WEBROOT=/opt/myphpsrc/ -v /opt/php7/var:/usr/local/php/var/ -p 9008:9000 -v /opt/php7/conf.d/xtra.conf:/usr/local/php/etc/php-fpm.d/xtra.conf ubuntu:php-fpm7.2-v3
echo "
documentroot: /opt/nginx/html/
expose port: 9008
"
}

plugins() {
# true v2 plugins for wordpress
docker run -d --rm  -v /etc/localtime:/etc/localtime:ro -v /opt/nginx/html/:/opt/myphpsrc -e WEBROOT=/opt/myphpsrc/ -v /opt/php7/var:/usr/local/php/var/ -p 9008:9000 -v /opt/php7/conf.d/xtra.conf:/usr/local/php/etc/php-fpm.d/xtra.conf ubuntu:php-fpm7.2-plugins-v3
echo "
documentroot: /opt/nginx/html/
expose port: 9008
"
}
# 单独分离一个配置文件的目的是aliyun的主机配置太低， 启动进程多了进程切换太多


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
