#!/usr/bin/env bash
#
# Description: TeamSpeak installation script.
#
# Copyright (C) 2023 - 2025 honeok <honeok@duck.com>
# https://www.honeok.com
# https://github.com/honeok/cross/raw/master/play/ts.sh
#
# shellcheck disable=SC2164

yellow='\033[1;33m'
red='\033[1;31m'
green='\033[1;32m'
white='\033[0m'
_yellow() { echo -e "${yellow}$*${white}"; }
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }

_err_msg() { echo -e "\033[41m\033[1m警告${white} $*"; }
_suc_msg() { echo -e "\033[42m\033[1m成功${white} $*"; }

separator() { printf "%-40s\n" "=" | sed 's/\s/=/g'; }

export DEBIAN_FRONTEND=noninteractive

[ "$(id -u)" -ne "0" ] && _err_msg "$(_red 'This script must be run as root！')" && exit 1

if [ "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" != "/root" ]; then
    cd /root >/dev/null 2>&1
fi

teamspeak_workdir='/data/docker_data/teamspeak'

[ -d "$teamspeak_workdir" ] && rm -rf $teamspeak_workdir >/dev/null 2>&1

enable() {
    local cmd
    local service_name="$1"
    if command -v apk >/dev/null 2>&1; then
        cmd="sudo rc-update add $service_name default"
    else
        cmd="sudo /usr/bin/systemctl enable $service_name"
    fi

    if $cmd; then
        _suc_msg "$(_green "${service_name}已设置为开机自启")"
    else
        _err_msg "$(_red "${service_name}设置开机自启失败")"
    fi
}

start() {
    local cmd
    local service_name="$1"
    
    if command -v apk >/dev/null 2>&1; then
        cmd="sudo service $service_name start"
    else
        cmd="sudo /usr/bin/systemctl start $service_name"
    fi

    if $cmd; then
        _suc_msg "$(_green "${service_name}已启动")"
    else
        _err_msg "$(_red "${service_name}启动失败")"
    fi
}

docker_compose() {
    local docker_compose_cmd
    if docker compose version >/dev/null 2>&1; then
        docker_compose_cmd='docker compose'
    elif command -v docker-compose >/dev/null 2>&1; then
        docker_compose_cmd='docker-compose'
    fi

    case "$1" in
        start)
            $docker_compose_cmd up -d
            ;;
        ps)
            $docker_compose_cmd ps
            ;;
        logs)
            $docker_compose_cmd logs
            ;;
    esac
}

pre_check() {
    local country=""
    local cloudflare_api ipinfo_api ipsb_api

    cloudflare_api=$(curl -A "Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0" -m 10 -s "https://dash.cloudflare.com/cdn-cgi/trace" | sed -n 's/.*loc=\([^ ]*\).*/\1/p')
    ipinfo_api=$(curl -fsL --connect-timeout 5 https://ipinfo.io/country)
    ipsb_api=$(curl -fsL --connect-timeout 5 -A Mozilla https://api.ip.sb/geoip | sed -n 's/.*"country_code":"\([^"]*\)".*/\1/p')

    for api in "$cloudflare_api" "$ipinfo_api" "$ipsb_api"; do
        if [ -n "$api" ]; then
            country="$api"
            break
        fi
    done

    if [ -z "$country" ]; then
        _err_msg "$(_red 'Failed to obtain the server location. Please check your network connection!')"
        exit 1
    fi

    if [[ "$country" == "CN" || $(curl -fsL -o /dev/null -w "%{time_total}" --max-time 5 https://raw.githubusercontent.com/honeok/cross/master/README.md) -gt 3 ]]; then
        github_proxy="https://gh-proxy.com/"
    else
        github_proxy=""
    fi
}

check_teamspeak() {
    if docker ps --format '{{.Image}}' | grep -q "teamspeak"; then
        _err_msg "$(_red 'TeamSpeak容器正在运行，请不要重复安装')"
        exit 1
    fi
}

install_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        if [[ "${country}" == "CN" ]]; then
            curl -fsL -o "get-docker.sh" "${github_proxy}https://raw.githubusercontent.com/honeok/Tools/master/docker/install.sh" && chmod +x get-docker.sh
            sh get-docker.sh --mirror Aliyun
            rm -f get-docker.sh
        else
            curl -fsL https://get.docker.com | sh
        fi
    fi
    enable docker
    start docker
}

install_teamspeak() {
    mkdir -p "${teamspeak_workdir}" && cd "${teamspeak_workdir}" || exit 1

    curl -fsL "${github_proxy}https://raw.githubusercontent.com/honeok/config/master/docker/compose/ts-docker-compose.yml" -o docker-compose.yml

    if [[ "${country}" == "CN" ]]; then
        sed -i 's|image: teamspeak:3.13.7|image: registry.cn-chengdu.aliyuncs.com/honeok/teamspeak:3.13.7|' docker-compose.yml
        sed -i 's|image: mariadb:11.4.2|image: registry.cn-chengdu.aliyuncs.com/honeok/mariadb:11.4.2|' docker-compose.yml
    fi

    docker_compose start

    _suc_msg "$(_green '您的TeamSpeak服务器搭建完毕！请在云服务器防火墙放行9987/UDP、10011/TCP、30033/TCP端口')"
    echo
    docker_compose ps
    separator
    docker_compose logs
}

main () {
    pre_check
    check_teamspeak
    install_docker
    install_teamspeak
}

main