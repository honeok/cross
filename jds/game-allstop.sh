#!/usr/bin/env bash
#
# Description: Parallel stop game server
#
# Copyright (C) 2024 honeok <yihaohey@gmail.com>
# Blog: www.honeok.com
# https://github.com/honeok/cross/blob/master/jds/game-allstop.sh

# set -x

server_range=$(seq 1 5)   # Game服务器范围

yellow='\033[1;33m'
red='\033[1;31m'
green='\033[1;32m'
white='\033[0m'
_yellow() { echo -e "${yellow}$@${white}"; }
_red() { echo -e "${red}$@${white}"; }
_green() { echo -e ${green}$@${white}; }

separator() { printf "%-15s\n" "=" | sed 's/\s/=/g'; }

# 处理守护进程
clear
cd /data/tool || { _red "无法进入 /data/tool 目录"; exit 1; }
processcontrol_pid=$(pgrep -f processcontrol-allserver.sh >/dev/null 2>&1)
if [ -n "$processcontrol_pid" ]; then
    pkill -9 -f processcontrol-allserver.sh
    [ -f "control.txt" ] && > control.txt
    [ -f "dump.txt" ] && > dump.txt
    _green "PID：[${processcontrol_pid}] processcontrol-allserver.sh进程已终止"
else
    _red "processcontrol-allserver.sh进程未运行无需终止"
fi

# 停止login和gate
cd /data/server/login/ && ./server.sh stop
cd /data/server/gate/ && ./server.sh stop
for i in $(seq 1 120); do
    echo -ne "\r${green}${i}${white}"
    sleep 1
done
_green "login和gate服务器已停止"

# 并行处理game
for i in $server_range; do
    (
        _yellow "正在处理server$i"
        cd /data/server$i/game/
        ./server.sh flush
        sleep 60
        ./server.sh stop
    ) &
done

separator
for j in $(seq 1 60); do
    echo -ne "\r${green}${j}${white}"
    sleep 1
done

# 等待并行任务
wait

echo -ne "\r"
_green "所有Game服务器已完成Flush和Stop操作"