#!/usr/bin/env bash
#
# Description: entrypoint script to perform parameter checks and start the x-ui service.
#
# Copyright (c) 2025 honeok <honeok@duck.com>
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

# /usr/local/bin # x-ui -h
# Usage of ./x-ui:
#   -v	show version

# Commands:
#     run            run web panel
#     v2-ui          migrate form v2-ui
#     setting        set settings

WORKDIR="/usr/local/bin"

# https://www.graalvm.org/latest/reference-manual/ruby/UTF8Locale
export LANG=en_US.UTF-8

separator() { printf "%-50s\n" "-" | sed 's/\s/-/g'; }

cd "$WORKDIR" || { printf "Error: Failed to enter the x-ui work directory!\n"; exit 1; }

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

check_config() {
    local IPV4_ADDRESS IPV6_ADDRESS
    local SHOW_IP=()
    local IS_PANEL_PORT=""

    # References: https://github.com/bin456789/reinstall
    # www.prologis.cn
    # www.autodesk.com.cn
    # www.keysight.com.cn
    is_ip() {
        IPV4_ADDRESS=$(curl -fsSL -m 5 -4 http://www.qualcomm.cn/cdn-cgi/trace 2>/dev/null | grep '^ip=' | cut -d= -f2 | xargs)
        IPV6_ADDRESS=$(curl -fsSL -m 5 -6 http://www.qualcomm.cn/cdn-cgi/trace 2>/dev/null | grep '^ip=' | cut -d= -f2 | xargs)
        [ -n "$IPV4_ADDRESS" ] && SHOW_IP+=("$IPV4_ADDRESS")
        [ -n "$IPV6_ADDRESS" ] && SHOW_IP+=("$IPV6_ADDRESS")
    }

    # For security reasons, it is necessary to mandatorily change the port and account password after installation or update.
    if [ ! -f "/etc/x-ui/x-ui.db" ]; then
        printf "\n"
        printf "                  \033[42m\033[1m%s\033[0m\n" "login info"
        separator
        if [ -z "$USER_NAME" ] || [ -z "$USER_PASSWORD" ]; then
            USERNAME_TEMP=$(head -c 6 /dev/urandom | base64)
            PASSWD_TEMP=$(head -c 6 /dev/urandom | base64)
            xray-ui setting -username "$USERNAME_TEMP" -password "$PASSWD_TEMP" >/dev/null 2>&1
            printf " Panel login username: %s\n" "$USERNAME_TEMP"
            printf " Panel login user password: %s\n" "$PASSWD_TEMP"
        fi
        if [ -z "$PANEL_PORT" ]; then
            generate_port
            IS_PANEL_PORT="$WEB_PORT"
            xray-ui setting -port "$WEB_PORT" >/dev/null 2>&1
            printf " Panel login port: %s\n" "$WEB_PORT"
        fi
        if [ -n "$USER_NAME" ] && [ -n "$USER_PASSWORD" ]; then
            xray-ui setting -username "$USER_NAME" -password "$USER_PASSWORD" >/dev/null 2>&1
            printf " Panel login username: %s\n" "$USER_NAME"
            printf " Panel login user password: %s\n" "$USER_PASSWORD"
        fi
        if [ -n "$PANEL_PORT" ]; then
            IS_PANEL_PORT="$PANEL_PORT"
            xray-ui setting -port "$PANEL_PORT" >/dev/null 2>&1
            printf " Panel login port: %s\n" "$PANEL_PORT"
        fi
        is_ip
        printf " Panel login address: "
        for IP in "${SHOW_IP[@]}"; do
            [[ "$IP" == *:* ]] && printf "[%s]:%s " "$IP" "$IS_PANEL_PORT" || printf "%s:%s " "$IP" "$IS_PANEL_PORT"
        done
        printf "\n"
        separator
        printf "\n"
    fi
}

check_config

if [ "$#" -eq 0 ]; then
    exec "xray-ui"
else
    exec "$@"
fi