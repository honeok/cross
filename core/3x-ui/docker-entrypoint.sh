#!/usr/bin/env bash
#
# Description: This script is used to configure the 3x-ui basic operating environment as the container startup entry.
#
# Copyright (c) 2025 honeok <i@honeok.com>
#
# SPDX-License-Identifier: GPL-2.0

separator() { printf "%-50s\n" "-" | sed 's/\s/-/g'; }

# 各变量默认值
WORKDIR="/usr/local/bin"

cd "$WORKDIR" || { echo >&2 "Error: Failed to enter the 3x-ui work directory!"; exit 1; }

# 生成随机字符
randomChar() {
    local LENGTH="$1"

    RANDOM_STRING="$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$LENGTH" | head -n1)"
    echo "$RANDOM_STRING"
}

# 生成随机端口
randomPort() {
    local IS_USED_PORT=""
    local IS_COUNT TEMP_PORT

    isPort() {
        [ ! "$IS_USED_PORT" ] && IS_USED_PORT="$(netstat -tunlp | sed -n 's/.*:\([0-9]\+\).*/\1/p' | sort -nu)"
        echo "$IS_USED_PORT" | sed 's/ /\n/g' | grep ^"${1}"$
        return
    }

    for ((IS_COUNT=1; IS_COUNT<=5; IS_COUNT++)); do
        TEMP_PORT="$(shuf -i 10000-65535 -n1)"
        if [ ! "$(isPort "$TEMP_PORT")" ]; then
            WEB_PORT="$TEMP_PORT" && break
        fi
        if [ "$IS_COUNT" -eq 5 ]; then
            echo >&2 "Error: no free port found after 5 attempts." && exit 1
        fi
    done
}

ipAddr() {
    # 获取一个登录IP即返回
    IPV4_ADDRESS="$(curl -kLs -m3 -4 http://www.qualcomm.cn/cdn-cgi/trace 2>/dev/null | grep -i '^ip=' | cut -d'=' -f2 | grep .)"
    IPV6_ADDRESS="$(curl -kLs -m3 -6 http://www.qualcomm.cn/cdn-cgi/trace 2>/dev/null | grep -i '^ip=' | cut -d'=' -f2 | grep .)"
    if [ -n "$IPV4_ADDRESS" ]; then
        echo "$IPV4_ADDRESS" && return
    fi
    if [ -n "$IPV6_ADDRESS" ]; then
        echo "[$IPV6_ADDRESS]" && return
    fi
    if [ -z "$IPV4_ADDRESS" ] && [ -z "$IPV6_ADDRESS" ]; then
        echo >&2 "Error: Could not retrieve public IP."; exit 1
    fi
}

checkConfig() {
    local PUBLIC_IP
    PUBLIC_IP="$(ipAddr)"

    if [ ! -f "/etc/x-ui/x-ui.db" ]; then
        echo
        printf "                  \033[42m\033[1m%s\033[0m\n" "login info"
        separator
        if [ -z "$USER_NAME" ] || [ -z "$USER_PASSWORD" ] || [ -z "$BASE_PATH" ] || [ -z "$PANEL_PORT" ]; then
            USERNAME_TEMP="$(randomChar 10)"
            PASSWD_TEMP="$(randomChar 10)"
            BASEPATH_TEMP="$(randomChar 15)"
            randomPort
            3x-ui setting -username "$USERNAME_TEMP" -password "$PASSWD_TEMP" -port "$WEB_PORT" -webBasePath "$BASEPATH_TEMP" >/dev/null 2>&1
            echo " Panel login username: $USERNAME_TEMP"
            echo " Panel login user password: $PASSWD_TEMP"
            echo " Panel login Port: $WEB_PORT"
            echo " Panel login WebBasePath: $BASEPATH_TEMP"
            echo " Panel login address: http://$PUBLIC_IP:$WEB_PORT/$BASEPATH_TEMP"
        fi
        if [ -n "$USER_NAME" ] && [ -n "$USER_PASSWORD" ] && [ -n "$BASE_PATH" ] && [ -n "$PANEL_PORT" ]; then
            3x-ui setting -username "$USER_NAME" -password "$USER_PASSWORD" -port "$PANEL_PORT" -webBasePath "$BASE_PATH" >/dev/null 2>&1
            echo " Panel login username: $USER_NAME"
            echo " Panel login user password: $USER_PASSWORD"
            echo " Panel login Port: $PANEL_PORT"
            echo " Panel login WebBasePath: $BASE_PATH"
            echo " Panel login address: http://$PUBLIC_IP:$PANEL_PORT/$BASE_PATH"
        fi
        separator
        echo
    fi
    /usr/local/bin/3x-ui migrate >/dev/null 2>&1
}

checkConfig

if [ "$#" -eq 0 ]; then
    exec 3x-ui
else
    exec "$@"
fi