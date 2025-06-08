#!/usr/bin/env bash
#
# Description: This script is used 3x-ui management panel, providing basic 3x-ui backend management.
#
# Copyright (c) 2025 honeok <honeok@disroot.org>
#
# SPDX-License-Identifier: GPL-2.0-only

# shellcheck disable=SC2009

# https://www.graalvm.org/latest/reference-manual/ruby/UTF8Locale
export LANG=en_US.UTF-8

red='\033[31m'
green='\033[32m'
yellow='\033[33m'
white='\033[0m'
_red() { printf "$red%s$white\n" "$*"; }
_green() { printf "$green%s$white\n" "$*"; }
_yellow() { printf "$yellow%s$white\n" "$*"; }
separator() { printf "%-19s\n" "-" | sed 's/\s/-/g'; }
reading() { read -rep "$(_yellow "$1")" "$2"; }

WORKDIR="/usr/local/bin"

cd "$WORKDIR" || { printf "Error: Failed to enter the 3x-ui work directory!\n"; exit 1; }

clear_screen() {
    [ -t 1 ] && tput clear 2>/dev/null || echo -e "\033[2J\033[H" || clear
}

show_status() {
    if ps | grep '[3]x-ui' >/dev/null 2>&1; then
        echo " 面板状态: $(_green 'Running')"
    else
        echo " 面板状态: $(_red 'Not Running')"
    fi
    if ps | grep '[x]ray-linux' >/dev/null 2>&1; then
        echo " Xray状态: $(_green 'Running')"
    else
        echo " Xray状态: $(_red 'Not Running')"
    fi
}

generate_string() {
    local LENGTH="$1"

    RANDOM_STRING=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$LENGTH" | head -n 1)
    echo "$RANDOM_STRING"
}

reset_user() {
    local CHOOSE USERNAME_TEMP PASSWD_TEMP

    reading ' 您确定要重置面板的用户名和密码吗? (y/n) ' 'CHOOSE'
    case "$CHOOSE" in
        [Yy]*|"")
            reading ' 请设置登录用户名[默认为随机用户名]: ' 'USERNAME_TEMP'
            [ -z "$USERNAME_TEMP" ] && USERNAME_TEMP=$(date +%s%N | md5sum | cut -c 1-8)
            reading ' 请设置登录密码[默认为随机密码]: ' 'PASSWD_TEMP'
            [ -z "$PASSWD_TEMP" ] && PASSWD_TEMP=$(date +%s%N | md5sum | cut -c 1-8)
            3x-ui setting -username "$USERNAME_TEMP" -password "$PASSWD_TEMP" >/dev/null 2>&1
            3x-ui setting -remove_secret >/dev/null 2>&1
            printf " 面板登录用户名已重置为: %s" "$(_green "$USERNAME_TEMP")"
            printf " 面板登录密码已重置为: %s" "$(_green "$PASSWD_TEMP")"
            printf " 面板登录密码令牌已禁用\n"
            printf " 请使用新的登录用户名和密码访问x-ui面板\n"
        ;;
        *)
            show_menu
        ;;
    esac
    exit 0
}

reset_basepath() {
    local CHOOSE BASEPATH_TEMP

    _yellow ' 重置Web基础路径'
    reading ' 确定要重置web基本路径吗? (y/n): ' 'CHOOSE'
    case "$CHOOSE" in
        [Yy]*|"")
            BASEPATH_TEMP=$(generate_string 10)
            # 应用新的web基础路径设置
            3x-ui setting -webBasePath "$BASEPATH_TEMP" >/dev/null 2>&1
            printf " Web基本路径已重置为: %s\n" "$BASEPATH_TEMP"
            printf " 请使用新的web基础路径访问面板\n"
        ;;
        *)
            show_menu
        ;;
    esac
    exit 0
}

reset_config() {
    local CHOOSE

    reading ' 您确定要重置所有面板设置, 帐户数据不会丢失, 用户名和密码不会更改! (y/n) ' 'CHOOSE'
    case "$CHOOSE" in
        [Yy]*|"")
            3x-ui setting -reset
            printf " 所有面板设置均已重置为默认值\n"
        ;;
        *)
            show_menu
        ;;
    esac
    exit 0
}

set_port() {
    local CHOOSE
    reading ' 输入端口号[1-65535]: ' 'CHOOSE'
    case "$CHOOSE" in
        [Yy]*|"")
            3x-ui setting -port "$CHOOSE"
            printf " 设置端口完毕, 现在请重启面板, 并使用新设置的端口 %s 访问面板\n" "$(_green "$CHOOSE")"
        ;;
        *)
            show_menu
        ;;
    esac
    exit 0
}

check_config() {
    local CONFIG_ROW
    echo
    separator
    3x-ui setting -show true | while IFS= read -r CONFIG_ROW; do
        _green "$CONFIG_ROW"
    done
    separator
}

show_menu() {
    clear_screen
    _green ' x-ui 面板管理脚本'
    echo
    echo " $(_green '0.') 退出脚本"
    separator
    echo " $(_green '1.') 重置用户名密码Secret Token"
    echo " $(_green '2.') 重置面板设置"
    echo " $(_green '3.') 重置Web基础路径"
    echo " $(_green '4.') 设置面板端口"
    echo " $(_green '5.') 查看当前面板信息"
    separator
    echo
    show_status
    echo
    reading ' 请输入选择 [0-5], 查看面板登录信息请输入数字5: ' 'CHOOSE'
    case "$CHOOSE" in
        0) clear_screen; exit 0 ;;
        1) reset_user ;;
        2) reset_basepath ;;
        3) reset_config ;;
        4) set_port ;;
        5) check_config ;;
        *) _red ' 请输入正确的数字 [0-5], 查看面板登录信息请输入数字5!' ;;
    esac
}

show_menu