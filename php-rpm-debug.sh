cat > /opt/php7/conf.d/xtra.conf << EOF
;;;;;;;;;;;;;;;;;;;;;
; FPM Configuration ;
;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;
; Global Options ;
;;;;;;;;;;;;;;;;;;

[global]
pid = php-fpm.pid
error_log = log/php-fpm-extra.log
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
user = www-data
group = www-data

pm = dynamic
pm.max_children = 12
pm.start_servers = 8
pm.min_spare_servers = 6
pm.max_spare_servers = 12
pm.max_requests = 2048
pm.process_idle_timeout = 10s
request_terminate_timeout = 120
request_slowlog_timeout = 0

pm.status_path = /php-fpm_status
slowlog = var/log/slow.log
rlimit_files = 51200
rlimit_core = 0

catch_workers_output = yes
;env[HOSTNAME] = localhost.localdomain
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp
EOF

#docker  run --rm  -v /etc/localtime:/etc/localtime:ro -v  /alidata/www/cakephp/ams/:/alidata/www/cakephp/ams/ -e WEBROOT=/alidata/www/cakephp/ams/ -v /opt/php7/var:/usr/local/php/var/ -v /opt/php7/conf.d/xtra.conf:/etc/php/7.2/fpm/pool.d/xtra.conf  -p 9009:9000 php:v1 php-fpm7.2 -F

# curl 127.0.0.1:81 请求需要使用php-fpm的web网站 
# 2504669952] [client 127.0.0.1:40479] AH01071: Got error 'PHP message: PHP Warning:  include(Cake/bootstrap.php): failed to open stream: No such file or directory in /alidata/www/cakephp/ams/webroot/index.php on line 100\nPHP message: PHP Warning:  include(): Failed opening 'Cake/bootstrap.php' for inclusion (include_path='/alidata/www/cakephp/lib:.:/usr/share/php') in /alidata/www/cakephp/ams/webroot/index.php on line 100\nPHP message: PHP Fatal error:  CakePHP core could not be found. Check the value of CAKE_CORE_INCLUDE_PATH in APP/webroot/index.php. It should point to the directory containing your /cake core directory and your /vendors root directory. in /alidata/www/cakephp/ams/webroot/index.php on line 109\n'
# 挂载路径/alidata/www/cakephp/lib 这个路径是读不到的

docker  run --rm  -v /etc/localtime:/etc/localtime:ro -v  /alidata/:/alidata/ -e WEBROOT=/alidata/www/cakephp/ams/ -v /opt/php7/var:/usr/local/php/var/ -v /opt/php7/conf.d/xtra.conf:/etc/php/7.2/fpm/pool.d/xtra.conf  -p 9009:9000 php:v1 php-fpm7.2 -F
# curl 1270.0.1:81 正常了，就权限问题。所以编译安装的结果修改一下挂载路径



