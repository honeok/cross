#!/usr/bin/env bash
## Author: honeok
## Blog: www.honeok.com
## Github: https://github.com/honeok

## set -x

logbak="/data/logbak"

if [ ! -d "$logbak" ]; then
    mkdir "$logbak" -p
fi

## 处理服务的检查、重启、日志记录等操作
restart_service() {
    local service_name=$1
    local server_path=$2

    # 检查服务是否运行
    if ! pgrep -f "$server_path" > /dev/null; then
        # 服务没有运行，进行重启操作
        log_message "$service_name-已重启"
        cd $server_path
        cp -f nohup.txt "$logbak/${service_name}_$(date +'%Y-%m-%d %H:%M:%S').txt"
        rm -f nohup.txt
        ./server.sh start &
    else
        # 服务正在运行，记录状态
        log_message "$service_name-正在运行"
    fi
}

## 记录日志
log_message() {
    local message=$1
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $message" >> /data/tool/control.txt &
}

## 循环检查服务状态
while true; do
    for i in {1..5}; do
        restart_service "Game$i" "/data/server$i/game"
        sleep 5s
    done

    restart_service "Gate" "/data/server/gate"
    sleep 5s

    restart_service "Login" "/data/server/login"
    sleep 5s
done