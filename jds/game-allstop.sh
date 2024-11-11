#!/bin/bash
## Author: honeok
## Blog: www.honeok.com

## Debug
## set -x

yellow='\033[93m'        # 亮黄色
red='\033[91m'           # 亮红色
green='\033[92m'         # 亮绿色
white='\033[0m'          # 重置
_yellow() { echo -e ${yellow}$@${white}; }
_red() { echo -e ${red}$@${white}; }
_green() { echo -e ${green}$@${white}; }

cd /data/tool/
if pgrep -f processcontrol-allserver.sh >/dev/null 2>&1; then
    pkill -9 -f processcontrol-allserver.sh
    > control.txt
    > dump.txt
    _green "processcontrol进程已终止文件已清空"
else
    _red "processcontrol进程未运行无需终止"
fi

cd /data/server/login/ && ./server.sh stop
cd /data/server/gate/ && ./server.sh stop && sleep 120s

_green "login和gate服务器已停止"

for i in {1..5}; do
    (
        _yellow "正在处理server$i"
        cd /data/server$i/game/
        ./server.sh flush
        sleep 60s
        ./server.sh stop
    ) &
done

# 等待所有并行操作完成
wait
_green "所有Game服务器已完成Flush和Stop操作"