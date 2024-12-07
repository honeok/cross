#!/usr/bin/env bash
#
# Description: Akile Monitor Manage Script.
#
# Copyright (C) 2024 honeok <honeok@duck.com>
# Blog: www.honeok.com
# https://github.com/honeok/cross/blob/master/nezha/install.sh

yellow='\033[93m'
red='\033[31m'
green='\033[92m'
blue='\033[94m'
cyan='\033[96m'
purple='\033[95m'
gray='\033[37m'
orange='\033[38;5;214m'
white='\033[0m'
_yellow() { echo -e ${yellow}$@${white}; }
_red() { echo -e ${red}$@${white}; }
_green() { echo -e ${green}$@${white}; }
_blue() { echo -e ${blue}$@${white}; }
_cyan() { echo -e ${cyan}$@${white}; }
_purple() { echo -e ${purple}$@${white}; }
_gray() { echo -e ${gray}$@${white}; }
_orange() { echo -e ${orange}$@${white}; }

bg_yellow='\033[48;5;220m'
bg_red='\033[41m'
bg_green='\033[42m'
bold='\033[1m'
_bg_yellow() { echo -e "${bg_yellow}${bold}$@${white}"; }
_bg_red() { echo -e "${bg_red}${bold}$@${white}"; }
_bg_green() { echo -e "${bg_green}${bold}$@${white}"; }

info_msg=$(_bg_yellow 提示)
err_msg=$(_bg_red 警告)
suc_msg=$(_bg_green 成功)
_info_msg() { echo -e "$info_msg $@"; }
_err_msg() { echo -e "$err_msg $@"; }
_suc_msg() { echo -e "$suc_msg $@"; }

AK_BASE_PATH="/etc/akile"
AK_DASHBOARD_PATH="${AK_BASE_PATH}/dashboard"
AK_AGENT_PATH="${AK_BASE_PATH}/client"
AK_DASHBOARD_SERVICE="/etc/systemd/system/akile-dashboard.service"
AK_DASHBOARD_SERVICERC="/etc/init.d/akile-dashboard"

[ "$EUID" -ne "0" ] && _err_msg "$(_red '需要root用户才能运行！')" && exit 1

ip_address() {
    local ipv4_services=("ipv4.ip.sb" "ipv4.icanhazip.com" "v4.ident.me" "api.ipify.org")
    local ipv6_services=("ipv6.ip.sb" "ipv6.icanhazip.com" "v6.ident.me" "api6.ipify.org")
    ipv4_address=""
    ipv6_address=""
    for service in "${ipv4_services[@]}"; do
        ipv4_address=$(curl -fskL4 -m 3 "$service")
        if [[ "$ipv4_address" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            break
        fi
    done
    for service in "${ipv6_services[@]}"; do
        ipv6_address=$(curl -fskL6 -m 3 "$service")
        if [[ "$ipv6_address" =~ ^[0-9a-fA-F:]+$ ]]; then
            break
        fi
    done
}

geo_check() {
    local response
    local cloudflare_api="https://blog.cloudflare.com/cdn-cgi/trace https://dash.cloudflare.com/cdn-cgi/trace https://developers.cloudflare.com/cdn-cgi/trace"
    local user_agent="Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0"
    # set -- "$cloudflare_api"
    for url in $cloudflare_api; do
        response=$(curl -A "$user_agent" -m 10 -s "$url")
        [ -n "$response" ] && country=$(echo "$response" | grep -oP 'loc=\K\w+')
        [ ! -z "$country" ] && break
    done
    [ -z "$country" ] && _err_msg "$(_red '无法获取服务器所在地区，请检查网络！')" && exit 1
}

cdn_check() {
    ip_address
    geo_check

    if [[ "$country" == "CN" || ( -z "$ipv4_address" && -n "$ipv6_address" ) || \
        $(curl -fsSkL -o /dev/null -w "%{time_total}" --max-time 5 https://raw.githubusercontent.com/honeok/cross/master/README.md) > 3 ]]; then
        github_proxy="https://gh-proxy.com/"
    else
        github_proxy=""
    fi
}

warp_check() {
    local response warp_ipv4 warp_ipv6
    local cloudflare_api="https://blog.cloudflare.com/cdn-cgi/trace https://dash.cloudflare.com/cdn-cgi/trace https://developers.cloudflare.com/cdn-cgi/trace"
    # set -- "$cloudflare_api"
    for url in $cloudflare_api; do
        response=$(curl -fskL4 -m 3 "$url" | grep warp | cut -d= -f2)
        [ "$response" == 'on' ] && { warp_ipv4=on; break; } || warp_ipv4=off
    done

    for url in $cloudflare_api; do
        response=$(curl -fskL6 -m 3 "$url" | grep warp | cut -d= -f2)
        [ "$response" == 'on' ] && { warp_ipv6=on; break; } || warp_ipv6=off
    done
}

geo_check
cdn_check
warp_check

daemon_reload() {
    if ! command -v apk >/dev/null 2>&1; then
        if command -v systemctl >/dev/null 2>&1; then
            /usr/bin/systemctl daemon-reload
        fi
    fi
}

systemctl() {
    local cmd="$1"
    local service_name="$2"

    if command -v apk >/dev/null 2>&1; then
        service "$service_name" "$cmd"
    else
        /usr/bin/systemctl "$cmd" "$service_name"
    fi
}

main() {
    local choice

    while true; do
        clear
        echo "- Akile monitor 管理脚本 -"
        echo "-------------------------"
        echo "1. 安装主控后端"
        echo "-------------------------"
        echo "0. 返回主菜单"
        echo "-------------------------"

        echo -n -e "${yellow}请输入选项并按回车键确认: ${white}"
        read -r choice

        case $choice in
            1)
            ;;
            *)
            ;;
        esac
    done
}