#!/usr/bin/env bash
## Author: honeok
## Blog: www.honeok.com
## Github: https://github.com/honeok
## Edit: 2024.11.22

openserver_time=$(date -u -d '+8 hours' +"%Y-%m-%dT%H:00:00")
server_password="c4h?itwj5ENi"

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

## 未安装则安装sshpass
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

remote_command="
cd /data/server${server_number}/game || exit 1 && \
sed -i 's|local open_server_time = \"[^\"]*\"|local open_server_time = \"$openserver_time\"|' lua/config/profile.lua || exit 1 && \
./server.sh reload || exit 1 && \
cd /data/server/login || exit 1 && \
sed -i '/${server_number}/d' etc/white_list.txt || exit 1 && \
./server.sh reload || exit 1
"

sshpass -p "$server_password" ssh -o StrictHostKeyChecking=no root@$server_ip "$remote_command"