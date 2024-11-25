#!/usr/bin/env bash
## Author: honeok
## Blog: www.honeok.com
## Github: https://github.com/honeok
## Edit: 2024.11.26 01:20

openserver_time=$(date -u -d '+8 hours' +"%Y-%m-%dT%H:00:00")
server_password="c4h?itwj5ENi"

## 检查输入参数
if [[ ${#} -ne 1 || ! $1 =~ ^[0-9]+$ ]]; then
    exit 1
else
    server_number=$1
fi

## 根据区服编号匹配服务器IP
if (( server_number >= 1 && server_number <= 5 )); then
    server_ip="10.46.99.216"
elif (( server_number >= 6 && server_number <= 10 )); then
    server_ip="192.168.1.2"
else
    exit 1
fi

send_message() {
    local action="$1"
    local country=$(curl -s ipinfo.io/country || echo "unknown")
    local os_info=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d '"' -f 2 | sed 's/ (.*)//')
    local cpu_arch=$(uname -m)

    curl -s -X POST "https://api.honeok.com/api/log" \
        -H "Content-Type: application/json" \
        -d "{\"action\":\"$action\",\"timestamp\":\"$(date -u '+%Y-%m-%d %H:%M:%S' -d '+8 hours')\",\"country\":\"$country\",\"os_info\":\"$os_info\",\"cpu_arch\":\"$cpu_arch\"}" &>/dev/null &
}

## 检查并安装 sshpass
if ! command -v sshpass &>/dev/null; then
    if command -v dnf &>/dev/null; then
        dnf update -y && dnf install epel-release -y && dnf install sshpass -y
    elif command -v yum &>/dev/null; then
        yum update -y && yum install epel-release -y && yum install sshpass -y
    elif command -v apt &>/dev/null; then
        apt update -y && apt install sshpass -y
    else
        exit 1
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
else
    send_message "[server${server_number} 开服失败]"
fi