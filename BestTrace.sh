#!/usr/bin/env bash
#
# Description: A BestTrace Script by honeok
#
# Copyright (C) 2024 honeok <yihaohey@gmail.com>
# Blog: www.honeok.com
# Github: https://github.com/honeok/shell/blob/master/BestTrace.sh

yellow='\033[1;33m'       # 黄色
red='\033[1;31m'          # 红色
green='\033[1;32m'        # 绿色
blue='\033[1;34m'         # 蓝色
cyan='\033[1;36m'         # 青色
white='\033[0m'           # 白色

_yellow() { echo -e ${yellow}$@${white}; }
_red() { echo -e ${red}$@${white}; }
_green() { echo -e ${green}$@${white}; }
_blue() { echo -e ${blue}$@${white}; }
_cyan() { echo -e ${cyan}$@${white}; }
_orange() { echo -e ${orange}$@${white}; }

if [ ! -f "/usr/local/bin/nexttrace" ]; then
    curl nxtrace.org/nt | bash
fi

next() {
    printf "%-70s\n" "-" | sed 's/\s/-/g'
}

clear
next

ip_list=(219.141.147.210 202.96.209.133 58.60.188.222 202.106.50.1 210.22.97.1 210.21.196.6 221.179.155.161 211.136.112.200 120.196.165.24 202.112.14.151)
ip_addr=(北京电信 上海电信 深圳电信 北京联通 上海联通 深圳联通 北京移动 上海移动 深圳移动 成都教育网)

for i in {0..9}
do
    echo ${ip_addr[$i]}
    nexttrace -M ${ip_list[$i]}
    next
done