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

## 日志路径
log_dirs=(
    "/data/server/gate/log"
    "/data/server/login/log"
    "/data/server1/game/log"
    "/data/server2/game/log"
    "/data/server3/game/log"
    "/data/server4/game/log"
    "/data/server5/game/log"
)

## 清理日志
for log_dir in "${log_dirs[@]}"; do
    if [ -d "$log_dir" ]; then
        _yellow "正在删除一个月以前的日志: ${log_dir}"

        # 查找并删除30天之前的 .log 文件
        find "$log_dir" -type f -name "*.log" -mtime +30 -exec rm -f {} \; && _green "${log_dir}中超过30天的日志已删除！" || _red "$log_dir 日志删除失败！"
    else
        _red "${log_dir}不存在，跳过！"
    fi
done

_green "日志清理完成！"