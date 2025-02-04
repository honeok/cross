#!/usr/bin/env bash
#
# Description: The most convenient route tracing tool based on NextTrace.
#
# Copyright (C) 2024 - 2025 honeok <honeok@duck.com>
#
# https://github.com/honeok/cross/raw/master/bestTrace.sh
#
# This script utilizes NextTrace, a powerful network diagnostic tool.
# NextTrace is copyrighted and developed by the NextTrace project team.
# For more details about NextTrace, visit: https://github.com/nxtrace
#
# License Information:
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License, version 3 or later.
#
# This program is distributed WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <https://www.gnu.org/licenses/>.

# shellcheck disable=SC2034,SC2207

version='v0.0.3 (2025.01.07)'

yellow='\033[1;33m'
red='\033[1;31m'
green='\033[1;32m'
white='\033[0m'
_yellow() { echo -e "${yellow}$*${white}"; }
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }

_err_msg() { echo -e "\033[41m\033[1m警告${white} $*"; }

short_separator() { printf "%-50s\n" "-" | sed 's/\s/-/g'; }

# https://www.nodeseek.com/post-68572-1 https://www.nodeseek.com/post-129987-1
trace_area_nmg=("内蒙古电信" "内蒙古联通" "内蒙古移动")
trace_ip_nmg_v4=("nm-ct-v4.ip.zstaticcdn.com" "nm-cu-v4.ip.zstaticcdn.com" "nm-cm-v4.ip.zstaticcdn.com")
trace_ip_nmg_v6=("nm-ct-v6.ip.zstaticcdn.com" "nm-cu-v6.ip.zstaticcdn.com" "nm-cm-v6.ip.zstaticcdn.com")
trace_area_hlj=("黑龙江电信" "黑龙江联通" "黑龙江移动")
trace_ip_hlj_v4=("hl-ct-v4.ip.zstaticcdn.com" "hl-cu-v4.ip.zstaticcdn.com" "hl-cm-v4.ip.zstaticcdn.com")
trace_ip_hlj_v6=("hl-ct-v6.ip.zstaticcdn.com" "hl-cu-v6.ip.zstaticcdn.com" "hl-cm-v6.ip.zstaticcdn.com")
trace_area_xj=("新疆电信" "新疆联通" "新疆移动")
trace_ip_xj_v4=("xj-ct-v4.ip.zstaticcdn.com" "xj-cu-v4.ip.zstaticcdn.com" "xj-cm-v4.ip.zstaticcdn.com")
trace_ip_xj_v6=("xj-ct-v6.ip.zstaticcdn.com" "xj-cu-v6.ip.zstaticcdn.com" "xj-cm-v6.ip.zstaticcdn.com")
trace_area_tj=("天津电信" "天津联通" "天津移动")
trace_ip_tj_v4=("tj-ct-v4.ip.zstaticcdn.com" "tj-cu-v4.ip.zstaticcdn.com" "tj-cm-v4.ip.zstaticcdn.com")
trace_ip_tj_v6=("tj-ct-v6.ip.zstaticcdn.com" "tj-cu-v6.ip.zstaticcdn.com" "tj-cm-v6.ip.zstaticcdn.com")
trace_area_bj=("北京电信" "北京联通" "北京移动")
trace_ip_bj_v4=("bj-ct-v4.ip.zstaticcdn.com" "bj-cu-v4.ip.zstaticcdn.com" "bj-cm-v4.ip.zstaticcdn.com")
trace_ip_bj_v6=("bj-ct-v6.ip.zstaticcdn.com" "bj-cu-v6.ip.zstaticcdn.com" "bj-cm-v6.ip.zstaticcdn.com")
trace_area_ln=("辽宁电信" "辽宁联通" "辽宁移动")
trace_ip_ln_v4=("ln-ct-v4.ip.zstaticcdn.com" "ln-cu-v4.ip.zstaticcdn.com" "ln-cm-v4.ip.zstaticcdn.com")
trace_ip_ln_v6=("ln-ct-v6.ip.zstaticcdn.com" "ln-cu-v6.ip.zstaticcdn.com" "ln-cm-v6.ip.zstaticcdn.com")
trace_area_hb=("河北电信" "河北联通" "河北移动")
trace_ip_hb_v4=("he-ct-v4.ip.zstaticcdn.com" "he-cu-v4.ip.zstaticcdn.com" "he-cm-v4.ip.zstaticcdn.com")
trace_ip_hb_v6=("he-ct-v6.ip.zstaticcdn.com" "he-cu-v6.ip.zstaticcdn.com" "he-cm-v6.ip.zstaticcdn.com")
trace_area_sd=("山东电信" "山东联通" "山东移动")
trace_ip_sd_v4=("sd-ct-v4.ip.zstaticcdn.com" "sd-cu-v4.ip.zstaticcdn.com" "sd-cm-v4.ip.zstaticcdn.com")
trace_ip_sd_v6=("sd-ct-v6.ip.zstaticcdn.com" "sd-cu-v6.ip.zstaticcdn.com" "sd-cm-v6.ip.zstaticcdn.com")
trace_area_js=("江苏电信" "江苏联通" "江苏移动")
trace_ip_js_v4=("js-ct-v4.ip.zstaticcdn.com" "js-cu-v4.ip.zstaticcdn.com" "js-cm-v4.ip.zstaticcdn.com")
trace_ip_js_v6=("js-ct-v6.ip.zstaticcdn.com" "js-cu-v6.ip.zstaticcdn.com" "js-cm-v6.ip.zstaticcdn.com")
trace_area_zj=("浙江电信" "浙江联通" "浙江移动")
trace_ip_zj_v4=("zj-ct-v4.ip.zstaticcdn.com" "zj-cu-v4.ip.zstaticcdn.com" "zj-cm-v4.ip.zstaticcdn.com")
trace_ip_zj_v6=("zj-ct-v6.ip.zstaticcdn.com" "zj-cu-v6.ip.zstaticcdn.com" "zj-cm-v6.ip.zstaticcdn.com")
trace_area_fj=("福建电信" "福建联通" "福建移动")
trace_ip_fj_v4=("fj-ct-v4.ip.zstaticcdn.com" "fj-cu-v4.ip.zstaticcdn.com" "fj-cm-v4.ip.zstaticcdn.com")
trace_ip_fj_v6=("fj-ct-v6.ip.zstaticcdn.com" "fj-cu-v6.ip.zstaticcdn.com" "fj-cm-v6.ip.zstaticcdn.com")
trace_area_ah=("安徽电信" "安徽联通" "安徽移动")
trace_ip_ah_v4=("ah-ct-v4.ip.zstaticcdn.com" "ah-cu-v4.ip.zstaticcdn.com" "ah-cm-v4.ip.zstaticcdn.com")
trace_ip_ah_v6=("ah-ct-v6.ip.zstaticcdn.com" "ah-cu-v6.ip.zstaticcdn.com" "ah-cm-v6.ip.zstaticcdn.com")
trace_area_jx=("江西电信" "江西联通" "江西移动")
trace_ip_jx_v4=("jx-ct-v4.ip.zstaticcdn.com" "jx-cu-v4.ip.zstaticcdn.com" "jx-cm-v4.ip.zstaticcdn.com")
trace_ip_jx_v6=("jx-ct-v6.ip.zstaticcdn.com" "jx-cu-v6.ip.zstaticcdn.com" "jx-cm-v6.ip.zstaticcdn.com")
trace_area_xz=("西藏电信" "西藏联通" "西藏移动")
trace_ip_xz_v4=("xz-ct-v4.ip.zstaticcdn.com" "xz-cu-v4.ip.zstaticcdn.com" "xz-cm-v4.ip.zstaticcdn.com")
trace_ip_xz_v6=("xz-ct-v6.ip.zstaticcdn.com" "xz-cu-v6.ip.zstaticcdn.com" "xz-cm-v6.ip.zstaticcdn.com")
trace_area_sc=("四川电信" "四川联通" "四川移动")
trace_ip_sc_v4=("sc-ct-v4.ip.zstaticcdn.com" "sc-cu-v4.ip.zstaticcdn.com" "sc-cm-v4.ip.zstaticcdn.com")
trace_ip_sc_v6=("sc-ct-v6.ip.zstaticcdn.com" "sc-cu-v6.ip.zstaticcdn.com" "sc-cm-v6.ip.zstaticcdn.com")
trace_area_sh=("上海电信" "上海联通" "上海移动")
trace_ip_sh_v4=("sh-ct-v4.ip.zstaticcdn.com" "sh-cu-v4.ip.zstaticcdn.com" "sh-cm-v4.ip.zstaticcdn.com")
trace_ip_sh_v6=("sh-ct-v6.ip.zstaticcdn.com" "sh-cu-v6.ip.zstaticcdn.com" "sh-cm-v6.ip.zstaticcdn.com")
trace_area_gd=("广东电信" "广东联通" "广东移动")
trace_ip_gd_v4=("gd-ct-v4.ip.zstaticcdn.com" "gd-cu-v4.ip.zstaticcdn.com" "gd-cm-v4.ip.zstaticcdn.com")
trace_ip_gd_v6=("gd-ct-v6.ip.zstaticcdn.com" "gd-cu-v6.ip.zstaticcdn.com" "gd-cm-v6.ip.zstaticcdn.com")

usage=$(cat <<EOF

默认执行广东、上海、北京、四川三网回程

bash bestTrace.sh

可选参数：
    -nmg  # 内蒙古
    -hlj  # 黑龙江
    -xj   # 新疆
    -tj   # 天津
    -bj   # 北京
    -ln   # 辽宁
    -hb   # 河北
    -sd   # 山东
    -js   # 江苏
    -zj   # 浙江
    -fj   # 福建
    -ah   # 安徽
    -jx   # 江西
    -xz   # 西藏
    -sc   # 四川
    -sh   # 上海
    -gd   # 广东

指定参数示例:
  bash bestTrace.sh -h         # 帮助命令
  bash bestTrace.sh -nmg       # 测试内蒙古
  bash bestTrace.sh -nmg -hlj  # 同时测试内蒙古和黑龙江
  bash bestTrace.sh -nmg -d    # 测试后删除 nexttrace
EOF
)

ip_address() {
    local ipv4_services=("ipv4.ip.sb" "ipv4.icanhazip.com" "v4.ident.me")
    local ipv6_services=("ipv6.ip.sb" "ipv6.icanhazip.com" "v6.ident.me")
    ipv4_address=""
    ipv6_address=""
    for service in "${ipv4_services[@]}"; do
        ipv4_address=$(curl -fsL4 -m 3 "$service")
        if [[ "$ipv4_address" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            break
        fi
    done
    for service in "${ipv6_services[@]}"; do
        ipv6_address=$(curl -fsL6 -m 3 "$service")
        if [[ "$ipv6_address" =~ ^[0-9a-fA-F:]+$ ]]; then
            break
        fi
    done
}

geo_check() {
    local cloudflare_api ipinfo_api ipsb_api

    cloudflare_api=$(curl -sL -m 10 -A "Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0" "https://dash.cloudflare.com/cdn-cgi/trace" | sed -n 's/.*loc=\([^ ]*\).*/\1/p')
    ipinfo_api=$(curl -sL --connect-timeout 5 https://ipinfo.io/country)
    ipsb_api=$(curl -sL --connect-timeout 5 -A Mozilla https://api.ip.sb/geoip | sed -n 's/.*"country_code":"\([^"]*\)".*/\1/p')

    for api in "$cloudflare_api" "$ipinfo_api" "$ipsb_api"; do
        if [ -n "$api" ]; then
            country="$api"
            break
        fi
    done

    if [ -z "$country" ]; then
        _err_msg "$(_red '无法获取服务器所在地区，请检查网络后重试！')"
        exit 1
    fi
}

nt_uninstall() {
    [ -f "/usr/local/bin/nexttrace" ] && rm -f "/usr/local/bin/nexttrace" >/dev/null 2>&1
    [ -f "/usr/bin/nexttrace" ] && rm -f "/usr/bin/nexttrace" >/dev/null 2>&1
}

nt_install() {
    geo_check

    if [[ "$country" == "CN" || ( -z "$ipv4_address" && -n "$ipv6_address" ) || \
        $(curl -fsL -o /dev/null -w "%{time_total}" --max-time 5 https://github.com/honeok/cross/raw/master/README.md) -gt 3 ]]; then
        github_proxy="https://gh-proxy.com/"
    else
        github_proxy=""
    fi

    if ! command -v nexttrace >/dev/null 2>&1 && [ ! -f "/usr/local/bin/nexttrace" ] && [ ! -f "/usr/bin/nexttrace" ]; then
        # bash <(curl -sL https://nxtrace.org/nt) || { _err_msg "$(_red 'Nexttrace安装失败')"; exit 1; }
        bash <(curl -sL "${github_proxy}https://github.com/nxtrace/NTrace-core/raw/main/nt_install.sh") || { _red "Nexttrace安装失败"; exit 1; }
        clear
    fi
}

# 遍历IP解析并路由追踪
perform_trace() {
    local -n areas=$1
    local -n ips=$2
    local resolved_ip

    for region in "${!areas[@]}"; do
        short_separator
        resolved_ip=$(getent hosts "${ips[region]}" | awk '{ print $1 }')
        # resolved_ip=$(host "${ips[region]}" | awk '/has address/ { print $4 }')

        if [[ -n "$resolved_ip" ]]; then
            _yellow "${areas[region]} ${resolved_ip}"
        else
            _red "${areas[region]} 未能解析域名${ips[region]}"
        fi
    
        # 使用域名执行追踪 (确保原始域名仍被使用)
        nexttrace -M "${ips[region]}"
    done
}

# 根据网络栈决定追踪类型
type_trace() {
    local ipv4_address=$1
    local ipv6_address=$2

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
        _err_msg "$(_red '无法检测到有效的网络栈，请检查网络配置！')"
        exit 1
    fi

    # 返回追踪类型
    echo "$trace_type_v4" "$trace_type_v6"
}

# 处理并执行追踪操作
exec_trace() {
    local area="$1"
    local ipv4_trace="$2"
    local ipv6_trace="$3"
    local trace_results

    trace_results=($(type_trace "$ipv4_address" "$ipv6_address"))
    trace_type_v4=${trace_results[0]}
    trace_type_v6=${trace_results[1]}

    $trace_type_v4 && perform_trace "$area" "$ipv4_trace"
    $trace_type_v6 && perform_trace "$area" "$ipv6_trace"
}

clear
_yellow "当前脚本版本: $version"
ip_address
nt_install

if [ "$#" -eq 0 ]; then
    exec_trace "trace_area_gd" "trace_ip_gd_v4" "trace_ip_gd_v6"
    exec_trace "trace_area_sh" "trace_ip_sh_v4" "trace_ip_sh_v6"
    exec_trace "trace_area_bj" "trace_ip_bj_v4" "trace_ip_bj_v6"
    exec_trace "trace_area_sc" "trace_ip_sc_v4" "trace_ip_sc_v6"
else
    for arg in "$@"; do
        case $arg in
            -nmg)
                exec_trace "trace_area_nmg" "trace_ip_nmg_v4" "trace_ip_nmg_v6"
                ;;
            -hlj)
                exec_trace "trace_area_hlj" "trace_ip_hlj_v4" "trace_ip_hlj_v6"
                ;;
            -xj)
                exec_trace "trace_area_xj" "trace_ip_xj_v4" "trace_ip_xj_v6"
                ;;
            -tj)
                exec_trace "trace_area_tj" "trace_ip_tj_v4" "trace_ip_tj_v6"
                ;;
            -bj)
                exec_trace "trace_area_bj" "trace_ip_bj_v4" "trace_ip_bj_v6"
                ;;
            -ln)
                exec_trace "trace_area_ln" "trace_ip_ln_v4" "trace_ip_ln_v6"
                ;;
            -hb)
                exec_trace "trace_area_hb" "trace_ip_hb_v4" "trace_ip_hb_v6"
                ;;
            -sd)
                exec_trace "trace_area_sd" "trace_ip_sd_v4" "trace_ip_sd_v6"
                ;;
            -js)
                exec_trace "trace_area_js" "trace_ip_js_v4" "trace_ip_js_v6"
                ;;
            -zj)
                exec_trace "trace_area_zj" "trace_ip_zj_v4" "trace_ip_zj_v6"
                ;;
            -fj)
                exec_trace "trace_area_fj" "trace_ip_fj_v4" "trace_ip_fj_v6"
                ;;
            -ah)
                exec_trace "trace_area_ah" "trace_ip_ah_v4" "trace_ip_ah_v6"
                ;;
            -jx)
                exec_trace "trace_area_jx" "trace_ip_jx_v4" "trace_ip_jx_v6"
                ;;
            -xz)
                exec_trace "trace_area_xz" "trace_ip_xz_v4" "trace_ip_xz_v6"
                ;;
            -sc)
                exec_trace "trace_area_sc" "trace_ip_sc_v4" "trace_ip_sc_v6"
                ;;
            -sh)
                exec_trace "trace_area_sh" "trace_ip_sh_v4" "trace_ip_sh_v6"
                ;;
            -gd)
                exec_trace "trace_area_gd" "trace_ip_gd_v4" "trace_ip_gd_v6"
                ;;
            -h)
                echo -e "$usage"
                ;;
            -d)
                nt_uninstall
                ;;
            *)
                _err_msg "$(_red "无效选项, 当前参数${arg}不被支持！")"
                echo -e "$usage"
                exit 1
                ;;
        esac
    done
fi
