#!/usr/bin/env bash
#
# Description: Automatically traces multiple IP addresses using nexttrace.
#
# Copyright (C) 2024 honeok <yihaohey@gmail.com>
# Blog: www.honeok.com
# Github: https://github.com/honeok/shell/blob/master/BestTrace.sh

yellow='\033[1;33m'
red='\033[1;31m'
green='\033[1;32m'
white='\033[0m'

_yellow() { echo -e "${yellow}$@${white}"; }
_red() { echo -e "${red}$@${white}"; }
_green() { echo -e "${green}$@${white}"; }

if ! command -v nexttrace >/dev/null 2>&1 && [ ! -f "/usr/local/bin/nexttrace" ]; then
	_yellow "Nexttrace正在安装！"
    curl -s nxtrace.org/nt | bash || { _red "Nexttrace安装失败！"; exit 1; }
fi

## 打印分隔线
separator() { printf "%-70s\n" "-" | sed 's/\s/-/g'; }

trace_area_gz=("广州电信" "广州联通" "广州移动")
trace_ip_gz=("58.60.188.222" "210.21.196.6" "120.196.165.24")

trace_area_sh=("上海电信" "上海联通" "上海移动")
trace_ip_sh=("202.96.209.133" "210.22.97.1" "211.136.112.200")

trace_area_bj=("北京电信" "北京联通" "北京移动")
trace_ip_bj=("219.141.147.210", "202.106.50.1", "221.179.155.161")

trace_area_cd=("成都电信" "成都联通" "成都移动")
trace_ip_cd=("61.139.2.69" "119.6.6.6" "211.137.96.205")

clear
separator

## 遍历和执行追踪
perform_trace() {
    local -n areas=$1
    local -n ips=$2

    for i in "${!areas[@]}"; do
        _yellow "${areas[i]} ${ips[i]}"
        nexttrace -M "${ips[i]}"
        separator
    done
}

perform_trace trace_area_gz trace_ip_gz
perform_trace trace_area_sh trace_ip_sh
perform_trace trace_area_bj trace_ip_bj
perform_trace trace_area_cd trace_ip_cd