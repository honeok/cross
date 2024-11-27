#!/usr/bin/env bash
#
# Description: Resident daemon in the game server backend
#
# Copyright (C) 2024 honeok <yihaohey@gmail.com>
# Blog: www.honeok.com
# https://github.com/honeok/cross/blob/master/jds/game-processcontrol.sh

# export LANG=en_US.UTF-8
# set -x

server_range=$(seq 1 5)   # Game服务器范围

beijing_time=$(date -d @$(($(curl -sL https://acs.m.taobao.com/gw/mtop.common.getTimestamp/ | awk -F'"t":"' '{print $2}' | cut -d '"' -f1) / 1000)) +"%Y-%m-%d %H:%M:%S")
base_path="/data/server"
app_name="p8_app_server"

# 日志备份目录校验
if [[ ! -d /data/logback ]];then
    mkdir -p /data/logback
fi

# API回调
send_message() {
    local action="$1"
    local country=$(curl -s ipinfo.io/country || echo "unknown")
    local os_info=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d '"' -f 2 | sed 's/ (.*)//')
    local cpu_arch=$(uname -m)

    curl -s -X POST "https://api.honeok.com/api/log" \
        -H "Content-Type: application/json" \
        -d "{\"action\":\"$action\",\"timestamp\":\"${beijing_time}\",\"country\":\"$country\",\"os_info\":\"$os_info\",\"cpu_arch\":\"$cpu_arch\"}" >/dev/null 2>&1 &
}

# 服务器运行状态校验
check_server() {
    local server_name=$1
    local server_dir=$2

    ## 检查服务器进程是否在运行，如果没有则进行重启操作
    if ! pgrep -f "$server_dir/$app_name" > /dev/null 2>&1; then
        # 服务没有运行进行重启操作
        cd "$server_dir" || return              # 进入服务器目录，如果失败则退出
        [[ -f nohup.txt ]] && cp -f nohup.txt "/data/logback/nohup_${server_name}_$(date -u '+%Y%m%d%H%M%S' -d '+8 hours').txt" && rm -f nohup.txt
        ./server.sh start &
        send_message "[${server_name} Restart]" # 发送重启通知
        echo "${beijing_time} [ERROR] $server_name Restart" >> /data/tool/control.txt &
    else
        echo "${beijing_time} [INFO] $server_name Running" >> /data/tool/control.txt &
    fi
}

while :; do
    # 检查server
    for i in $server_range; do
        server_name="server${i}"
        server_dir="${base_path}${i}/game"
        check_server "${server_name}" "${server_dir}"
        sleep 5s
    done

    # 检查gate
    check_server "gate" "${base_path}/gate"
    sleep 5s

    # 检查login
    check_server "login" "${base_path}/login"

    sleep 10s
done