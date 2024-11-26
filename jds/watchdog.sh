#!/usr/bin/env bash
#
# Copyright (C) 2024 honeok <yihaohey@gmail.com>
# Blog: www.honeok.com
# Description: Automatic server activation
# Github: https://github.com/honeok

# export LANG=en_US.UTF-8
# set -x

openserver_time=$(date -u -d '+8 hours' +"%Y-%m-%dT%H:00:00")
server_password="c4h?itwj5ENi"

cd /root >/dev/null 2>&1
watchdog_pid="/tmp/watchdog.pid"
if [ -f "$watchdog_pid" ] && kill -0 $(cat "$watchdog_pid") 2>/dev/null; then
    exit 1
fi
echo $$ > "$watchdog_pid"

## 终止信号捕获，意外中断时能优雅地处理
trap _exit SIGINT SIGQUIT SIGTERM SIGHUP

_exit() {
    if [ -f "$watchdog_pid" ]; then
        rm -f "$watchdog_pid"
    fi
    exit 0
}

## 输入参数校验
if [[ ${#} -ne 1 || ! $1 =~ ^[0-9]+$ ]]; then
    _exit
else
    server_number=$1
fi

## 根据区服编号匹配服务器IP
server_ip=""
if (( server_number >= 1 && server_number <= 5 )); then
    server_ip="10.46.99.216"
elif (( server_number >= 6 && server_number <= 10 )); then
    server_ip="192.168.1.2"
else
    _exit
fi

send_message() {
    local action="$1"
    local country=$(curl -s ipinfo.io/country || echo "unknown")
    local os_info=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d '"' -f 2 | sed 's/ (.*)//')
    local cpu_arch=$(uname -m)

    curl -s -X POST "https://api.honeok.com/api/log" \
        -H "Content-Type: application/json" \
        -d "{\"action\":\"$action\",\"timestamp\":\"$(date -u '+%Y-%m-%d %H:%M:%S' -d '+8 hours')\",\"country\":\"$country\",\"os_info\":\"$os_info\",\"cpu_arch\":\"$cpu_arch\"}" >/dev/null 2>&1 &
}

## 检查并安装 sshpass
if ! command -v sshpass >/dev/null 2>&1; then
    if command -v dnf >/dev/null 2>&1; then
        dnf update -y && dnf install epel-release -y && dnf install sshpass -y
    elif command -v yum >/dev/null 2>&1; then
        yum update -y && yum install epel-release -y && yum install sshpass -y
    elif command -v apt >/dev/null 2>&1; then
        apt update -y && apt install sshpass -y
    else
        _exit
    fi
fi

## 远程命令，修改开服时间重读Login
remote_command="\
## 进入游戏目录，修改开服时间
cd /data/server${server_number}/game || exit 1 && \
[ -f lua/config/profile.lua ] || exit 1 && \
sed -i '/^\s*local open_server_time\s*=/s|\"[^\"]*\"|\"'"$openserver_time"'\"|' lua/config/profile.lua || exit 1 && \
grep -q '^\s*local open_server_time\s*=\s*\"'"$openserver_time"'\"' lua/config/profile.lua || exit 1 && \
./server.sh reload || exit 1 && \

## 进入登录目录，修改白名单
cd /data/server/login || exit 1 && \
if [ -f etc/white_list.txt ]; then \
    sed -i '/^\s*'"${server_number}"'\s*$/d' etc/white_list.txt || exit 1 && \
    ! grep -q '^\s*'"${server_number}"'\s*$' etc/white_list.txt || exit 1; \
else \
    exit 1; \
fi && \
./server.sh reload || exit 1"

## SSH执行远程命令
if sshpass -p "$server_password" ssh -o StrictHostKeyChecking=no root@$server_ip "$remote_command"; then
    send_message "[server${server_number} 已开服]"
    _exit
else
    send_message "[server${server_number} 开服失败]"
    _exit
fi