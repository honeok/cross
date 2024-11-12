#!/usr/bin/env bash
## Author: honeok
## Blog: www.honeok.com
## Github: https://github.com/honeok

## set -x

app_name="p8_app_server"
current_date=$(date -u '+%Y-%m-%d %H:%M:%S' -d '+8 hours')
logbak="/data/logbak"
dump_log="/data/tool/dump.txt"

## 创建日志备份目录
if [ ! -d "$logbak" ]; then
    mkdir "$logbak" -p
fi

send_message() {
    local country=$(curl -s ipinfo.io/country)
    local os_info=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d '"' -f 2)
    local cpu_arch=$(uname -m)

    curl -s -X POST "https://api.honeok.com/api/log" \
        -H "Content-Type: application/json" \
        -d "{\"action\":\"$1\",\"timestamp\":\"$(date -u '+%Y-%m-%d %H:%M:%S' -d '+8 hours')\",\"country\":\"$country\",\"os_info\":\"$os_info\",\"cpu_arch\":\"$cpu_arch\"}" &>/dev/null &
}

## 处理服务的检查、重启、日志记录等操作
restart_service() {
    local service_name=$1
    local server_path=$2
    local restart_log=$3

    # 检查服务是否运行
    if ! pgrep -f "$server_path/$app_name" > /dev/null; then
        # 服务没有运行，进行重启操作
        cd $server_path
        cp -f nohup.txt "$logbak/${service_name}_${current_date}.txt"
        rm -f nohup.txt
        ./server.sh start &
        log_message "$service_name-已重启" "$restart_log"
        send_message "$service_name-已重启"
    else
        # 服务正在运行，记录状态
        log_message "$service_name-正在运行" "$dump_log"
    fi
}

## 记录日志
log_message() {
    local message=$1
    local log_file=$2
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $message" >> "$log_file" &
}

## 重启服务（适用于 Game 和 Gate、Login）
game_services() {
    for i in {1..5}; do
        restart_service "Game$i" "/data/server$i/game" "$dump_log"
        sleep 5s
    done

    restart_service "Gate" "/data/server/gate" "$dump_log"
    sleep 5s

    restart_service "Login" "/data/server/login" "$dump_log"
    sleep 5s
}

## 重启服务（适用于 Global 和 ZK1、ZK2、ZK3）
center_services() {
    restart_service "Global" "/data/center/global" "$dump_log"
    sleep 5s

    for i in {1..3};do
        restart_service "ZK$i" "/data/center/zk$i" "$dump_log"
        sleep 5s
    done
}

## main
while true; do
    ## 只对 Game 和 Gate、Login 服务进行操作
    if [[ -d "/data/server/login" ]]; then
        game_services
    fi

    ## 只对 Global 和 ZK1、ZK2、ZK3 服务进行操作
    if [[ -d "/data/center/global" ]];then
        center_services
    fi
done