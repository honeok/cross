#!/usr/bin/env bash
#
# Description: This script is used to configure the 3x-ui basic operating environment as the container startup entry.
#
# Copyright (c) 2025 honeok <honeok@disroot.org>
#
# SPDX-License-Identifier: GPL-2.0-only

WORKDIR="/usr/local/bin"

# https://www.graalvm.org/latest/reference-manual/ruby/UTF8Locale
export LANG=en_US.UTF-8

separator() { printf "%-50s\n" "-" | sed 's/\s/-/g'; }

cd "$WORKDIR" || { printf "Error: Failed to enter the 3x-ui work directory!\n" >&2; exit 1; }

generate_string() {
    local LENGTH="$1"

    RANDOM_STRING=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$LENGTH" | head -n 1)
    echo "$RANDOM_STRING"
}

generate_port() {
    local IS_USED_PORT=""
    local IS_COUNT TEMP_PORT

    is_port() {
        [ ! "$IS_USED_PORT" ] && IS_USED_PORT=$(netstat -tunlp | sed -n 's/.*:\([0-9]\+\).*/\1/p' | sort -nu)
        echo "$IS_USED_PORT" | sed 's/ /\n/g' | grep ^"${1}"$
        return
    }

    for ((IS_COUNT=1; IS_COUNT<=5; IS_COUNT++)); do
        TEMP_PORT=$(shuf -i 10000-65535 -n 1)
        if [ ! "$(is_port "$TEMP_PORT")" ]; then
            WEB_PORT="$TEMP_PORT" && break
        fi
        [ "$IS_COUNT" -eq 5 ] && { printf "Error: no free port found after 5 attempts.\n" >&2; exit 1; }
    done
}

ip_address() {
    # 获取一个登录IP即返回
    IPV4_ADDRESS=$(curl -fsL -m 5 -4 http://www.qualcomm.cn/cdn-cgi/trace 2>/dev/null | grep -i '^ip=' | cut -d'=' -f2 | grep .)
    IPV6_ADDRESS=$(curl -fsL -m 5 -6 http://www.qualcomm.cn/cdn-cgi/trace 2>/dev/null | grep -i '^ip=' | cut -d'=' -f2 | grep .)
    if [ -n "$IPV4_ADDRESS" ]; then
        printf "%s\n" "$IPV4_ADDRESS" && return
    fi
    if [ -n "$IPV6_ADDRESS" ]; then
        printf "%s\n" "[$IPV6_ADDRESS]" && return
    fi
    if [ -z "$IPV4_ADDRESS" ] && [ -z "$IPV6_ADDRESS" ]; then
        printf "Error: Could not retrieve public IP.\n" >&2; exit 1
    fi
}

check_config() {
    local PUBLIC_IP
    PUBLIC_IP="$(ip_address)"

    if [ ! -f "/etc/x-ui/x-ui.db" ]; then
        echo
        printf "                  \033[42m\033[1m%s\033[0m\n" "login info"
        separator
        if [ -z "$USER_NAME" ] || [ -z "$USER_PASSWORD" ] || [ -z "$BASE_PATH" ] || [ -z "$PANEL_PORT" ]; then
            USERNAME_TEMP=$(generate_string 10)
            PASSWD_TEMP=$(generate_string 10)
            BASEPATH_TEMP=$(generate_string 15)
            generate_port
            3x-ui setting -username "$USERNAME_TEMP" -password "$PASSWD_TEMP" -port "$WEB_PORT" -webBasePath "$BASEPATH_TEMP" >/dev/null 2>&1
            printf " Panel login username: %s\n" "$USERNAME_TEMP"
            printf " Panel login user password: %s\n" "$PASSWD_TEMP"
            printf " Panel login Port: %s\n" "$WEB_PORT"
            printf " Panel login WebBasePath: %s\n" "$BASEPATH_TEMP"
            printf " Panel login address: %s\n" "http://$PUBLIC_IP:$WEB_PORT/$BASEPATH_TEMP"
        fi
        if [ -n "$USER_NAME" ] && [ -n "$USER_PASSWORD" ] && [ -n "$BASE_PATH" ] && [ -n "$PANEL_PORT" ]; then
            3x-ui setting -username "$USER_NAME" -password "$USER_PASSWORD" -port "$PANEL_PORT" -webBasePath "$BASE_PATH" >/dev/null 2>&1
            printf " Panel login username: %s\n" "$USER_NAME"
            printf " Panel login user password: %s\n" "$USER_PASSWORD"
            printf " Panel login Port: %s\n" "$PANEL_PORT"
            printf " Panel login WebBasePath: %s\n" "$BASE_PATH"
            printf " Panel login address: %s\n" "http://$PUBLIC_IP:$PANEL_PORT/$BASE_PATH"
        fi
        separator
        echo
    fi
    /usr/local/bin/3x-ui migrate >/dev/null 2>&1
}

check_config

if [ "$#" -eq 0 ]; then
    exec 3x-ui
else
    exec "$@"
fi