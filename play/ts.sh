#!/usr/bin/env bash
#
# Description: TeamSpeak installation script
#
# Copyright (C) 2023 - 2024 honeok <yihaohey@gmail.com>
# Blog: https://www.honeok.com
# https://github.com/honeok/cross/blob/master/play/ts.sh

yellow='\033[1;33m'
red='\033[1;31m'
green='\033[1;32m'
white='\033[0m'
_yellow() { echo -e "${yellow}$@${white}"; }
_red() { echo -e "${red}$@${white}"; }
_green() { echo -e ${green}$@${white}; }

# Globle Install Path.
ts_workdir="/data/docker_data/teamspeak"

# Country Select
if [[ "$(curl -fskSL --connect-timeout 5 ipinfo.io/country)" == "CN" ]]; then
    country="CN"
else
    country=""
fi

# Github Proxy.
set_region_config() {
    if [[ "${country}" == "CN" ]]; then
        github_proxy="https://gh-proxy.com/"
    else
        github_proxy=""
    fi
}

# Use Region function set best github proxy.
set_region_config

########################################
# Check TeamSpeak Container.
if docker ps --format '{{.Image}}' | grep -q "teamspeak"; then
    _red "TeamSpeak容器正在运行，请不要重复安装。"
    exit 0
fi

# Check Docker Install.
if ! command -v docker >/dev/null 2>&1; then
    if [[ "${country}" == "CN" ]]; then
        cd ~
        curl -fskSL "${github_proxy}raw.githubusercontent.com/honeok/Tools/main/docker/install.sh" -o get-docker.sh && chmod +x get-docker.sh
        sh get-docker.sh --mirror Aliyun
        rm -f get-docker.sh
    else
        curl -fskSL https://get.docker.com | sh
    fi
fi

# Change Dir ts_workdir
mkdir -p "${ts_workdir}" && cd "${ts_workdir}"
curl -fskSL "${github_proxy}raw.githubusercontent.com/honeok/Tools/main/dockerapplication/ts-docker-compose.yml" -o docker-compose.yml
if [[ "${country}" == "CN" ]]; then
    sed -i 's|image: teamspeak:3.13.7|image: registry.cn-chengdu.aliyuncs.com/honeok/teamspeak:3.13.7|' docker-compose.yml
    sed -i 's|image: mariadb:11.4.2|image: registry.cn-chengdu.aliyuncs.com/honeok/mariadb:11.4.2|' docker-compose.yml
fi

# Run TeamSpeak Server
docker compose up -d
_yellow "您的TeamSpeak服务器搭建完毕！请在云服务器防火墙放行9987/UDP、10011/TCP、30033/TCP端口。"
sleep 1s && _yellow "Bey！"
docker compose ps
echo "======================================================="
docker compose logs