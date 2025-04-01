#!/usr/bin/env bash
#
# Description: The most convenient route tracing tool based on NextTrace.
#
# Copyright (c) 2024-2025 honeok <honeok@duck.com>
#
# This script utilizes NextTrace, a powerful network diagnostic tool.
# NextTrace is copyrighted and developed by the NextTrace project team.
# For more details about NextTrace, visit: https://github.com/nxtrace
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

# shellcheck disable=SC2034

# 当前脚本版本号
readonly version='v0.1.4 (2025.04.01)'

red='\033[91m'
green='\033[92m'
yellow='\033[93m'
cyan='\033[96m'
white='\033[0m'
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }
_yellow() { echo -e "${yellow}$*${white}"; }
_cyan() { echo -e "${cyan}$*${white}"; }

_err_msg() { echo -e "\033[41m\033[1mError${white} $*"; }

# 分割符
separator() { printf "%-70s\n" "-" | sed 's/\s/-/g'; }

# 各变量默认值
github_proxy='https://goppx.com/'
ua_browser='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36'

# https://dnsdaquan.com
# https://www.nodeseek.com/post-68572-1
# https://www.nodeseek.com/post-129987-1
declare -a area_bj=("北京电信" "北京联通" "北京移动")
declare -a bj_v4=("219.141.140.10" "123.123.123.124" "221.179.155.161")
declare -a bj_v6=("2400:89c0:1053:3::69" "2400:89c0:1013:3::54" "2409:8c00:8421:1303::55")

declare -a area_sh=("上海电信" "上海联通" "上海移动")
declare -a sh_v4=("202.96.209.133" "210.22.97.1" "211.136.112.200")
declare -a sh_v6=("240e:e1:aa00:4000::24" "2408:80f1:21:5003::a" "2409:8c1e:75b0:3003::26")

declare -a area_gz=("广州电信" "广州联通" "广州移动")
declare -a gz_v4=("58.60.188.222" "210.21.196.6" "120.196.165.24")
declare -a gz_v6=("240e:97c:2f:3000::44" "2408:8756:f50:1001::c" "2409:8c54:871:1001::12")

declare -a area_cd=("成都电信" "成都联通" "成都移动")
declare -a cd_v4=("61.139.2.69" "119.6.6.6" "211.137.96.205")
declare -a cd_v6=("240e:974:e601:200::14" "2408:8766:1:14::18" "2409:8c62:e10:79::1b")

print_title() {
    echo "------------------- A bestTrace.sh Script By honeok ------------------"
    echo " Version            : $(_green "$version") $(_red "\xe2\x99\xbb\xef\xb8\x8f")"
    echo " $(_cyan 'bash <(curl -sL https://github.com/honeok/cross/raw/master/bestTrace.sh)')"
}

_exists() {
    local _cmd="$1"
    if type "$_cmd" >/dev/null 2>&1; then
        return 0
    elif command -v "$_cmd" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 清屏函数
clear_screen() {
    if [ -t 1 ]; then
        tput clear 2>/dev/null || echo -e "\033[2J\033[H" || clear
    fi
}

# 运行前校验
pre_runcheck() {
    # 备用 www.prologis.cn
    # 备用 www.autodesk.com.cn
    # 备用 www.keysight.com.cn
    cloudflare_api='www.qualcomm.cn'

    if [ "$(id -ru)" -ne 0 ] || [ "$EUID" -ne 0 ]; then
        _err_msg "$(_red 'This script must be run as root!')" && exit 1
    fi
    if [ "$(ps -p $$ -o comm=)" != "bash" ] || readlink /proc/$$/exe | grep -q "dash"; then
        _err_msg "$(_red 'This script needs to be run with bash, not sh!')" && exit 1
    fi
    # 境外服务器仅ipv4访问测试通过后取消github代理
    if [ "$(curl -A "$ua_browser" -fskL -m 3 "https://$cloudflare_api/cdn-cgi/trace" | grep -i '^loc=' | cut -d'=' -f2 | xargs)" != "CN" ]; then
        unset github_proxy
    fi
    # 脚本当天及累计运行次数统计
    runcount=$(curl -fskL -m 10 --retry 1 "https://hits.honeok.com/bestTrace?action=hit")
}

# IP dual stack check
# https://www.shellcheck.net/wiki/SC2015
# shellcheck disable=SC2015
pre_ipcheck() {
    ipv4_check="false"
    ipv6_check="false"

    ping -4 -c 1 -W 4 1.1.1.1 >/dev/null 2>&1 && ipv4_check="true" || \
        { curl -sL -m 4 -4 ipinfo.io/ip >/dev/null 2>&1 && ipv4_check="true"; }

    ping -6 -c 1 -W 4 2606:4700:4700::1111 >/dev/null 2>&1 && ipv6_check="true" || \
        { curl -sL -m 4 -6 v6.ipinfo.io/ip >/dev/null 2>&1 && ipv6_check="true"; }

    if [ "$ipv4_check" = "false" ] && [ "$ipv6_check" = "false" ]; then
        _err_msg "$(_red 'Both IPv4 and IPv6 connectivity were not detected.')" && exit 1
    fi
}

nt_install() {
    if ! _exists nexttrace || [ ! -f "/usr/local/bin/nexttrace" ] || [ ! -f "/usr/bin/nexttrace" ]; then
        bash <(curl -fskL "${github_proxy}https://github.com/nxtrace/NTrace-core/raw/main/nt_install.sh") || { _err_msg "$(_red 'Nexttrace installation failed.')"; exit 1; }
    fi
    clear_screen
}

nt_uninstall() {
    [ -f "/usr/local/bin/nexttrace" ] && rm -f "/usr/local/bin/nexttrace" >/dev/null 2>&1
    [ -f "/usr/bin/nexttrace" ] && rm -f "/usr/bin/nexttrace" >/dev/null 2>&1
}

# 单地区追踪处理
trace_single() {
    local -n areas="$1"
    local -n ip_list="$2"
    local ip_address

    for operator in {0..2}; do
        separator
        ip_address="${ip_list[$operator]}"
        _yellow "${areas[$operator]} $ip_address"
        nexttrace -M "$ip_address"
    done
}

exec_bestTrace() {
    if [ "$ipv4_check" = "true" ] && [ "$ipv6_check" = "true" ]; then
        trace_single "area_bj" "bj_v4"
        trace_single "area_sh" "sh_v4"
        trace_single "area_gz" "gz_v4"
        trace_single "area_cd" "cd_v4"

        trace_single "area_bj" "bj_v6"
        trace_single "area_sh" "sh_v6"
        trace_single "area_gz" "gz_v6"
        trace_single "area_cd" "cd_v6"
    elif [ "$ipv4_check" = "true" ]; then
        trace_single "area_bj" "bj_v4"
        trace_single "area_sh" "sh_v4"
        trace_single "area_gz" "gz_v4"
        trace_single "area_cd" "cd_v4"
    elif [ "$ipv6_check" = "true" ]; then
        trace_single "area_bj" "bj_v6"
        trace_single "area_sh" "sh_v6"
        trace_single "area_gz" "gz_v6"
        trace_single "area_cd" "cd_v6"
    fi
}

print_end_msg() {
    local today total

    separator
    if [ -n "$runcount" ]; then
        today=$(echo "$runcount" | grep '"daily"' | sed 's/.*"daily": *\([0-9]*\).*/\1/')
        total=$(echo "$runcount" | grep '"total"' | sed 's/.*"total": *\([0-9]*\).*/\1/')
        echo "$(_yellow 'The script has run:') $(_cyan "$today") $(_yellow 'times today. Total executions:') $(_cyan "$total")"
    fi
}

bestTrace() {
    print_title
    pre_runcheck
    pre_ipcheck
    nt_install
    exec_bestTrace
    nt_uninstall
    print_end_msg
}

bestTrace