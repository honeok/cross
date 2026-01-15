#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0
#
# Description: The script sets up the 3x-ui runtime environment and initializes container startup configuration.
# Copyright (c) 2025-2026 honeok <i@honeok.com>

separator() { printf "%-50s\n" "-" | sed 's/\s/-/g'; }

WORKDIR="/usr/local/bin"

die() {
    echo >&2 "Error: $*"
    exit 1
}

cd "$WORKDIR" > /dev/null 2>&1 || die "Failed to enter the 3x-ui work directory."

curl() {
    local RET
    # 添加 --fail 不然404退出码也为0
    # 32位cygwin已停止更新, 证书可能有问题, 添加 --insecure
    # centos7 curl 不支持 --retry-connrefused --retry-all-errors 因此手动 retry
    for ((i = 1; i <= 5; i++)); do
        command curl --connect-timeout 10 --fail --insecure "$@"
        RET="$?"
        if [ "$RET" -eq 0 ]; then
            return
        else
            # 403 404 错误或达到重试次数
            if [ "$RET" -eq 22 ] || [ "$i" -eq 5 ]; then
                return "$RET"
            fi
            sleep 1
        fi
    done
}

# 生成随机字符
random_char() {
    local LENGTH="$1"

    RANDOM_STRING="$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w "$LENGTH" | head -n1)"
    echo "$RANDOM_STRING"
}

# 生成随机端口
random_port() {
    local USED_PORT TEMP_PORT

    is_port() {
        [ ! "$USED_PORT" ] && USED_PORT="$(netstat -tunlp | sed -n 's/.*:\([0-9]\+\).*/\1/p' | sort -nu)"
        echo "$USED_PORT" | sed 's/ /\n/g' | grep ^"${1}"$
        return
    }

    for ((i = 1; i <= 5; i++)); do
        TEMP_PORT="$(shuf -i 10000-65535 -n1)"
        if [ ! "$(is_port "$TEMP_PORT")" ]; then
            WEB_PORT="$TEMP_PORT"
            break
        fi
        [ "$i" -eq 5 ] && die "no free port found after 5 attempts."
    done
}

# 获取一个登录IP即返回
ip_address() {
    IPV4_ADDRESS="$(curl -Ls -4 http://www.qualcomm.cn/cdn-cgi/trace 2> /dev/null | grep -i '^ip=' | cut -d'=' -f2 | grep .)"
    IPV6_ADDRESS="$(curl -Ls -6 http://www.qualcomm.cn/cdn-cgi/trace 2> /dev/null | grep -i '^ip=' | cut -d'=' -f2 | grep .)"
    if [[ -n "$IPV4_ADDRESS" && "$IPV4_ADDRESS" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "$IPV4_ADDRESS"
        return
    fi
    if [[ -n "$IPV6_ADDRESS" && "$IPV6_ADDRESS" == *":"* ]]; then
        echo "[$IPV6_ADDRESS]"
        return
    fi
    die "Could not retrieve a valid public ip address."
}

check_config() {
    local PUBLIC_IP
    PUBLIC_IP="$(ip_address)"

    if [ ! -f "/etc/x-ui/x-ui.db" ]; then
        echo
        printf "%18s\033[42m\033[1m%s\033[0m\n" "" "login info"
        separator
        if [ -z "$USER_NAME" ] || [ -z "$USER_PASSWORD" ] || [ -z "$BASE_PATH" ] || [ -z "$PANEL_PORT" ]; then
            USERNAME_TEMP="$(random_char 10)"
            PASSWD_TEMP="$(random_char 10)"
            BASEPATH_TEMP="$(random_char 15)"
            random_port
            3x-ui setting -username "$USERNAME_TEMP" -password "$PASSWD_TEMP" -port "$WEB_PORT" -webBasePath "$BASEPATH_TEMP" > /dev/null 2>&1
            echo " Panel login username: $USERNAME_TEMP"
            echo " Panel login user password: $PASSWD_TEMP"
            echo " Panel login Port: $WEB_PORT"
            echo " Panel login WebBasePath: $BASEPATH_TEMP"
            echo " Panel login address: http://$PUBLIC_IP:$WEB_PORT/$BASEPATH_TEMP"
        fi
        if [ -n "$USER_NAME" ] && [ -n "$USER_PASSWORD" ] && [ -n "$BASE_PATH" ] && [ -n "$PANEL_PORT" ]; then
            3x-ui setting -username "$USER_NAME" -password "$USER_PASSWORD" -port "$PANEL_PORT" -webBasePath "$BASE_PATH" > /dev/null 2>&1
            echo " Panel login username: $USER_NAME"
            echo " Panel login user password: $USER_PASSWORD"
            echo " Panel login Port: $PANEL_PORT"
            echo " Panel login WebBasePath: $BASE_PATH"
            echo " Panel login address: http://$PUBLIC_IP:$PANEL_PORT/$BASE_PATH"
        fi
        separator
        echo
    fi
    /usr/local/bin/3x-ui migrate > /dev/null 2>&1
}

check_config

if [ "$#" -eq 0 ]; then
    exec 3x-ui
else
    exec "$@"
fi
