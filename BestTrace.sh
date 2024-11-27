#!/usr/bin/env bash
#
# Description: The most convenient route tracing.
#
# Copyright (C) 2024 honeok <yihaohey@gmail.com>
# Blog: https://www.honeok.com
# Twitter: https://twitter.com/hone0k
# https://github.com/honeok/cross/blob/master/BestTrace.sh
#
# Fork from zq: https://github.com/zq/shell/blob/master/autoBestTrace.sh || wget -qO- git.io/besttrace | bash

yellow='\033[1;33m'
red='\033[1;31m'
green='\033[1;32m'
white='\033[0m'

_yellow() { echo -e "${yellow}$@${white}"; }
_red() { echo -e "${red}$@${white}"; }
_green() { echo -e ${green}$@${white}; }

ip_address() {
    local ipv4_services=("ipv4.ip.sb" "api.ipify.org" "checkip.amazonaws.com" "ipinfo.io/ip")
    local ipv6_services=("ipv6.ip.sb" "api6.ipify.org" "v6.ident.me" "ipv6.icanhazip.com")

    ipv4_address=""
    ipv6_address=""

    # 获取IPv4地址
    for service in "${ipv4_services[@]}"; do
        ipv4_address=$(curl -s "$service")
        if [[ "$ipv4_address" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            break
        fi
    done

    # 获取IPv6地址
    for service in "${ipv6_services[@]}"; do
        ipv6_address=$(curl -s --max-time 2 "$service")
        if [[ "$ipv6_address" =~ ^[0-9a-fA-F:]+$ ]]; then
            break
        fi
    done
}

if ! command -v nexttrace >/dev/null 2>&1 && [ ! -f "/usr/local/bin/nexttrace" ]; then
    curl -s nxtrace.org/nt | bash || { _red "Nexttrace安装失败"; exit 1; }
    # bash <(curl -sL ${github_proxy}raw.githubusercontent.com/nxtrace/NTrace-core/main/nt_install.sh) ||  { _red "Nexttrace安装失败"; exit 1; }
fi

separator() { printf "%-70s\n" "-" | sed 's/\s/-/g'; }

## ===== 卸载逻辑 =====
uninstall_nexttrace(){
    separator
    for file in /usr/local/bin/nexttrace /usr/bin/nexttrace; do
        [[ -f $file ]] && rm -f "$file" && _green "已成功删除nexttrace！"
    done
}

## 全国各省份三网TCP-Ping IPV4 IPv6地址
# https://www.nodeseek.com/post-68572-1
# https://www.nodeseek.com/post-129987-1
trace_area_hlj=("黑龙江电信" "黑龙江联通" "黑龙江移动")
trace_ip_hlj_v4=("hl-ct-v4.ip.zstaticcdn.com" "hl-cu-v4.ip.zstaticcdn.com" "hl-cm-v4.ip.zstaticcdn.com")
trace_ip_hlj_v6=("hl-ct-v6.ip.zstaticcdn.com" "hl-cu-v6.ip.zstaticcdn.com" "hl-cm-v6.ip.zstaticcdn.com")
trace_area_nmg=("内蒙古电信" "内蒙古联通" "内蒙古移动")
trace_ip_nmg_v4=("nm-ct-v4.ip.zstaticcdn.com" "nm-cu-v4.ip.zstaticcdn.com" "nm-cm-v4.ip.zstaticcdn.com")
trace_ip_nmg_v6=("nm-ct-v6.ip.zstaticcdn.com" "nm-cu-v6.ip.zstaticcdn.com" "nm-cm-v6.ip.zstaticcdn.com")
trace_area_bj=("北京电信" "北京联通" "北京移动")
trace_ip_bj_v4=("bj-ct-v4.ip.zstaticcdn.com" "bj-cu-v4.ip.zstaticcdn.com" "bj-cm-v4.ip.zstaticcdn.com")
trace_ip_bj_v6=("bj-ct-v6.ip.zstaticcdn.com" "bj-cu-v6.ip.zstaticcdn.com" "bj-cm-v6.ip.zstaticcdn.com")
trace_area_js=("江苏电信" "江苏联通" "江苏移动")
trace_ip_js_v4=("js-ct-v4.ip.zstaticcdn.com" "js-cu-v4.ip.zstaticcdn.com" "js-cm-v4.ip.zstaticcdn.com")
trace_ip_js_v6=("js-ct-v6.ip.zstaticcdn.com" "js-cu-v6.ip.zstaticcdn.com" "js-cm-v6.ip.zstaticcdn.com")
trace_area_sd=("山东电信" "山东联通" "山东移动")
trace_ip_sd_v4=("sd-ct-v4.ip.zstaticcdn.com" "sd-cu-v4.ip.zstaticcdn.com" "sd-cm-v4.ip.zstaticcdn.com")
trace_ip_sd_v6=("sd-ct-v6.ip.zstaticcdn.com" "sd-cu-v6.ip.zstaticcdn.com" "sd-cm-v6.ip.zstaticcdn.com")
trace_area_sh=("上海电信" "上海联通" "上海移动")
trace_ip_sh_v4=("sh-ct-v4.ip.zstaticcdn.com" "sh-cu-v4.ip.zstaticcdn.com" "sh-cm-v4.ip.zstaticcdn.com")
trace_ip_sh_v6=("sh-ct-v6.ip.zstaticcdn.com" "sh-cu-v6.ip.zstaticcdn.com" "sh-cm-v6.ip.zstaticcdn.com")
trace_area_sc=("四川电信" "四川联通" "四川移动")
trace_ip_sc_v4=("sc-ct-v4.ip.zstaticcdn.com" "sc-cu-v4.ip.zstaticcdn.com" "sc-cm-v4.ip.zstaticcdn.com")
trace_ip_sc_v6=("sc-ct-v6.ip.zstaticcdn.com" "sc-cu-v6.ip.zstaticcdn.com" "sc-cm-v6.ip.zstaticcdn.com")
trace_area_gd=("广东电信" "广东联通" "广东移动")
trace_ip_gd_v4=("gd-ct-v4.ip.zstaticcdn.com" "gd-cu-v4.ip.zstaticcdn.com" "gd-cm-v4.ip.zstaticcdn.com")
trace_ip_gd_v6=("gd-ct-v6.ip.zstaticcdn.com" "gd-cu-v6.ip.zstaticcdn.com" "gd-cm-v6.ip.zstaticcdn.com")

clear

## ===== 遍历IP解析并trace =====
perform_trace() {
    local -n areas=$1
    local -n ips=$2
        
    for i in "${!areas[@]}"; do
        separator
        analysis=$(getent hosts "${ips[i]}" | awk '{ print $1 }')
        
        if [[ -n "$analysis" ]]; then
            _yellow "${areas[i]} ${analysis}"
        else
            _red "${areas[i]} 未能解析域名${ips[i]}"
        fi
    
        # 使用域名执行追踪（确保原始域名仍被使用）
        nexttrace -M "${ips[i]}"
    done
}

ip_address

# 根据网络栈决定追踪类型
trace_type_v4=false
trace_type_v6=false
if [[ -n "$ipv4_address" && -n "$ipv6_address" ]]; then
    trace_type_v4=true
    trace_type_v6=true
elif [[ -n "$ipv4_address" ]]; then
    trace_type_v4=true
elif [[ -n "$ipv6_address" ]]; then
    trace_type_v6=true
else
    _red "错误：无法检测到有效的网络栈，请检查网络配置！"
    exit 1
fi

case "$1" in
    -hlj)
        $trace_type_v4 && perform_trace trace_area_hlj trace_ip_hlj_v4
        $trace_type_v6 && perform_trace trace_area_hlj trace_ip_hlj_v6
        ;;
    -nmg)
        $trace_type_v4 && perform_trace trace_area_nmg trace_ip_nmg_v4
        $trace_type_v6 && perform_trace trace_area_nmg trace_ip_nmg_v6
        ;;
    -bj)
        $trace_type_v4 && perform_trace trace_area_bj trace_ip_bj_v4
        $trace_type_v6 && perform_trace trace_area_bj trace_ip_bj_v6
        ;;
    -js)
        $trace_type_v4 && perform_trace trace_area_js trace_ip_js_v4
        $trace_type_v6 && perform_trace trace_area_js trace_ip_js_v6
        ;;
    -sd)
        $trace_type_v4 && perform_trace trace_area_sd trace_ip_sd_v4
        $trace_type_v6 && perform_trace trace_area_sd trace_ip_sd_v6
        ;;
    -sh)
        $trace_type_v4 && perform_trace trace_area_sh trace_ip_sh_v4
        $trace_type_v6 && perform_trace trace_area_sh trace_ip_sh_v6
        ;;
    -sc)
        $trace_type_v4 && perform_trace trace_area_sc trace_ip_sc_v4
        $trace_type_v6 && perform_trace trace_area_sc trace_ip_sc_v6
        ;;
    -gd)
        $trace_type_v4 && perform_trace trace_area_gd trace_ip_gd_v4
        $trace_type_v6 && perform_trace trace_area_gd trace_ip_gd_v6
        ;;
    -d)
        uninstall_nexttrace
        ;;
    *)
        if [ -z "$1" ]; then
            $trace_type_v4 && perform_trace trace_area_gd trace_ip_gd_v4
            $trace_type_v4 && perform_trace trace_area_sh trace_ip_sh_v4
            $trace_type_v4 && perform_trace trace_area_bj trace_ip_bj_v4
            $trace_type_v4 && perform_trace trace_area_sc trace_ip_sc_v4
            $trace_type_v6 && perform_trace trace_area_gd trace_ip_gd_v6
            $trace_type_v6 && perform_trace trace_area_sh trace_ip_sh_v6
            $trace_type_v6 && perform_trace trace_area_bj trace_ip_bj_v6
            $trace_type_v6 && perform_trace trace_area_sc trace_ip_sc_v6
        else
            _red "错误：无效的参数，参数${1}不被支持！"
            echo -e "
支持的参数：
  -hlj  # 黑龙江三网回程
  -nmg  # 内蒙古三网回程
  -bj   # 北京三网回程
  -js   # 江苏三网回程
  -sd   # 山东三网回程
  -sh   # 上海三网回程
  -sc   # 四川三网回程
  -gd   # 广东三网回程

如果没有传参默认执行广东上海北京四川三网回程：
  ./BestTrace.sh
  ./BestTrace.sh -hlj      # 黑龙江

附加参数：
  -d  # 检测后删除nexttrace
  ./BestTrace.sh -hlj -d
"
        fi
        ;;
esac

if [ "$2" == "-d" ]; then
    uninstall_nexttrace
fi