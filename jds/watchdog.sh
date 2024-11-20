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

# 根据区服编号匹配服务器 IP
if (( server_number >= 1 && server_number <= 5 )); then
    server_ip="192.168.1.1"
elif (( server_number >= 6 && server_number <= 10 )); then
    server_ip="192.168.1.2"
else
    exit 1
fi

echo "Server IP: $server_ip"