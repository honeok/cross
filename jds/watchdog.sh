#!/usr/bin/env bash
#
# Description: Automatic server activation
#
# Copyright (C) 2024 honeok <yihaohey@gmail.com>
# Blog: www.honeok.com
# https://github.com/honeok/cross/blob/master/jds/watchdog.sh

# export LANG=en_US.UTF-8
# set -x

## ========== 系统预检 ==========
os_name=$(grep ^ID= /etc/*release | awk -F'=' '{print $2}' | sed 's/"//g')
if [[ "$os_name" != "debian" && "$os_name" != "ubuntu" && "$os_name" != "centos" && "$os_name" != "rocky" && "$os_name" != "alma" ]]; then
    exit 1
fi

[ "$(id -u)" -ne "0" ] && exit 1

if [ "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" != "/root" ]; then
    cd /root >/dev/null 2>&1
fi

## ========== 进程守护与信号处理 ==========
watchdog_pid="/tmp/watchdog.pid"
if [ -f "$watchdog_pid" ] && kill -0 $(cat "$watchdog_pid") 2>/dev/null; then
    exit 1
fi
echo $$ > "$watchdog_pid"

## 终止信号捕获，意外中断时能优雅地处理
trap _exit SIGINT SIGQUIT SIGTERM SIGHUP

_exit() {
    # 删除PID文件
    if [ -f "$watchdog_pid" ]; then
        rm -f "$watchdog_pid"
    fi
    exit 0
}

## ========== 脚本入参校验 ==========
if [[ ${#} -ne 1 || ! $1 =~ ^[0-9]+$ ]]; then
    _exit
else
    server_number=$1
fi

## ========== 所需时间相关 ==========
suning_timeapi=$(date -d @$(($(curl -sL https://f.m.suning.com/api/ct.do | awk -F'"currentTime": ' '{print $2}' | cut -d ',' -f1) / 1000)) +"%Y-%m-%dT%H:00:00")            # 苏宁时间API
taobao_timeapi=$(date -d @$(($(curl -sL https://acs.m.taobao.com/gw/mtop.common.getTimestamp/ | awk -F'"t":"' '{print $2}' | cut -d '"' -f1) / 1000)) +"%Y-%m-%dT%H:00:00") # 淘宝时间API
ddnspod_timeapi=$(date -d @$(($(curl -sL https://ip.ddnspod.com/timestamp) / 1000)) +"%Y-%m-%dT%H:00:00")
timeapi_timeapi=$(curl -sL --max-time 2 "https://timeapi.io/api/Time/current/zone?timeZone=Asia/Shanghai" | grep -oP '"dateTime":\s*"\K[^"]+' | sed 's/\.[0-9]*//g' | sed 's/:[0-9]*:[0-9]*$/:00:00/')

open_server_time=""

for api in "$suning_timeapi" "$taobao_timeapi" "$ddnspod_timeapi" "$timeapi_timeapi"; do
    open_server_time=$api  # 将当前API返回的时间赋值给open_server_time

    # 检查时间格式是否有效
    if [[ -n "$open_server_time" && "$open_server_time" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:00:00$ ]]; then
        break  # 如果获取到有效时间，跳出循环
    fi
done

# 如果没有成功获取时间，使用当前时间
if [[ -z "$open_server_time" || ! "$open_server_time" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:00:00$ ]]; then
    open_server_time=$(date -u -d '+8 hours' +"%Y-%m-%dT%H:00:00")  # 使用当前时间并调整为北京时间 (UTC+8)，如果系统时间同步不可用，时间偏差通常不会太大
fi

beijing_time=$(date -d @$(($(curl -sL https://acs.m.taobao.com/gw/mtop.common.getTimestamp/ | awk -F'"t":"' '{print $2}' | cut -d '"' -f1) / 1000)) +"%Y-%m-%dT%H:%M:%S")
# beijing_time=$(date -d @$(($(curl -sL https://f.m.suning.com/api/ct.do | awk -F'"currentTime": ' '{print $2}' | cut -d ',' -f1) / 1000)) +"%Y-%m-%dT%H:%M:%S")
# beijing_time=$(date -d @$(($(curl -sL https://ip.ddnspod.com/timestamp) / 1000)) +"%Y-%m-%dT%H:%M:%S")
# beijing_time=$(curl -sL --max-time 2 "https://timeapi.io/api/Time/current/zone?timeZone=Asia/Shanghai" | grep -oP '"dateTime":\s*"\K[^"]+' | sed 's/\.[0-9]*//g' | sed 's/T/ /')

## echo "xxxxxxxxxxxx" > /root/password.txt
## chmod 600 /root/password.txt 只有root用户可以读取该文件
[ -f /root/password.txt ] && [ -s /root/password.txt ] && server_password=$(cat /root/password.txt) || exit 1

## 根据区服编号匹配服务器IP
if (( server_number >= 1 && server_number <= 5 )); then
    server_ip="10.46.99.216"
elif (( server_number >= 6 && server_number <= 10 )); then
    server_ip="127.0.0.1"
else
    _exit
fi

## ========== API 回调 ==========
send_message() {
    local action="$1"
    local country=$(curl -s ipinfo.io/country || echo "unknown")
    local os_info=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d '"' -f 2 | sed 's/ (.*)//')
    local cpu_arch=$(uname -m)

    curl -s -X POST "https://api.honeok.com/api/log" \
        -H "Content-Type: application/json" \
        -d "{\"action\":\"$action\",\"timestamp\":\"$(date -u '+%Y-%m-%d %H:%M:%S' -d '+8 hours')\",\"country\":\"$country\",\"os_info\":\"$os_info\",\"cpu_arch\":\"$cpu_arch\"}" >/dev/null 2>&1 &
}

## ========== sshpass命令校验 ==========
if ! command -v sshpass >/dev/null 2>&1; then
    if command -v dnf >/dev/null 2>&1; then
        if ! rpm -q epel-release >/dev/null 2>&1; then
            dnf install epel-release -y
        fi
        dnf update -y && dnf install sshpass -y
    elif command -v yum >/dev/null 2>&1; then
        if ! rpm -q epel-release >/dev/null 2>&1; then
            yum install epel-release -y
        fi
        yum update -y && yum install sshpass -y
    elif command -v apt >/dev/null 2>&1; then
        apt update -y && apt install sshpass -y
    else
        _exit
    fi
fi

## ========== 构建远程命令 ==========
remote_command="\
## 进入游戏目录，修改开服时间
cd /data/server${server_number}/game || exit 1 && \
[ -f lua/config/profile.lua ] || exit 1 && \
sed -i '/^\s*local open_server_time\s*=/s|\"[^\"]*\"|\"'"$openserver_time"'\"|' lua/config/profile.lua || exit 1 && \
grep -q '^\s*local open_server_time\s*=\s*\"'"$openserver_time"'\"' lua/config/profile.lua || exit 1 && \
# 检查文件是否在过去1分钟内被修改
if ! find lua/config/profile.lua -mmin -1 >/dev/null 2>&1; then exit 1; fi && \
./server.sh reload || exit 1 && \

## 进入登录目录，修改白名单
cd /data/server/login || exit 1 && \
if [ -f etc/white_list.txt ]; then \
    sed -i '/^\s*'"${server_number}"'\s*$/d' etc/white_list.txt || exit 1 && \
    ! grep -q '^\s*'"${server_number}"'\s*$' etc/white_list.txt || exit 1; \
    # 检查文件是否在过去1分钟内被修改
    if ! find etc/white_list.txt -mmin -1 >/dev/null 2>&1; then exit 1; fi && \
else \
    exit 1; \
fi && \
./server.sh reload || exit 1"

## ========== 执行远程命令 ==========
# 三次重试机会
for (( i=1; i<=3; i++ )); do
    # 执行远程命令，捕获错误信息
    output=$(sshpass -p "$server_password" ssh -o StrictHostKeyChecking=no root@$server_ip "$remote_command" 2>&1)
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        # 如果远程命令执行成功，发送已开服消息
        send_message "[server${server_number}已开服]"
        echo "${beijing_time} [SUCCESS] server${server_number}已开服" >> watchdog.log 2>&1
        _exit
    fi

    # 如果是最后一次失败，发送失败消息并退出
    if (( i == 3 )); then
        send_message "[server${server_number}开服失败]"
        echo "${beijing_time} [ERROR] server${server_number}开服失败，错误信息: $output" >> watchdog.log 2>&1
        _exit
    fi

    # 使用指数退避策略增加等待时间
    sleep_time=$(( 5 * i ))  # 逐步增加等待时间：5秒、10秒、15秒
    echo "${beijing_time} [WARNING] 第${i}次尝试失败，错误信息: ${output}，等待${sleep_time}秒后重试" >> watchdog.log 2>&1

    # 暂停等待后重试
    sleep $sleep_time
done