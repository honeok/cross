#!/usr/bin/env bash
#
# Description: Test the routing of the three major network return lines on the server side.
#
# Copyright (c) 2024-2025 honeok <honeok@duck.com>
#
# References:
# https://github.com/oneclickvirt/backtrace
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

# https://www.graalvm.org/latest/reference-manual/ruby/UTF8Locale
export LANG=en_US.UTF-8

_red() { printf "\033[91m%s\033[0m\n" "$*"; }
_green() { printf "\033[92m%s\033[0m\n" "$*"; }
_err_msg() { printf "\033[41m\033[1mError\033[0m %s\n" "$*"; }
_suc_msg() { printf "\033[42m\033[1mSuccess\033[0m %s\n" "$*"; }

# 各变量默认值
GITHUB_PROXY='https://files.m.daocloud.io/'
UA_BROWSER='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36'

# 用于检查命令是否存在
_is_exists() {
    local _CMD="$1"
    if type "$_CMD" >/dev/null 2>&1; then return 0;
    elif command -v "$_CMD" >/dev/null 2>&1; then return 0;
    elif which "$_CMD" >/dev/null 2>&1; then return 0;
    else return 1;
    fi
}

# 清屏函数
clear_screen() {
    ( [ -t 1 ] && tput clear 2>/dev/null ) || echo -e "\033[2J\033[H" || clear
}

pre_check() {
    if [ "$EUID" -ne 0 ]; then
        _err_msg "$(_red 'This script must be run as root!')"; exit 1
    fi
    if [ "$(ps -p $$ -o comm=)" != "bash" ] || readlink /proc/$$/exe | grep -q "dash"; then
        _err_msg "$(_red 'This script needs to be run with bash, not sh!')"; exit 1
    fi
    if [ "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" != "/root" ]; then
        cd /root 2>/dev/null || { _err_msg "$(_red "Failed to change directory, Check permissions and try again!")"; exit 1; }
    fi
    # 境外服务器仅ipv4访问测试通过后取消github代理
    if [ "$(curl --user-agent "$UA_BROWSER" -fsL -m 3 --retry 2 -4 "http://www.qualcomm.cn/cdn-cgi/trace" | grep -i '^loc=' | cut -d'=' -f2 | grep .)" != "CN" ]; then
        unset GITHUB_PROXY
    fi
}

before_run() {
    [ -f "$HOME/backtrace" ] && rm -f "$HOME/backtrace" >/dev/null 2>&1
    [ -f /usr/bin/backtrace ] && rm -f /usr/bin/backtrace >/dev/null 2>&1
    [ -f /usr/local/bin/backtrace ] && rm -f /usr/local/bin/backtrace >/dev/null 2>&1
}

backtrace_install() {
    local OS_TYPE OS_ARCH
    OS_TYPE="$(uname -s 2>/dev/null | sed 's/[A-Z]/\L&/g')"

    # 定义支持的操作系统和架构
    if [ "$OS_TYPE" != linux ] && [ "$OS_TYPE" != darwin ] && [ "$OS_TYPE" != freebsd ] && [ "$OS_TYPE" != openbsd ]; then
        _err_msg "$(_red "Unsupported operating system: $OS_TYPE")"; exit 1
    fi

    case "$(uname -m)" in
        i*86)
            OS_ARCH="386"
        ;;
        x86_64|x86|amd64|x64)
            OS_ARCH="amd64"
        ;;
        armv*|aarch64|arm64)
            OS_ARCH="arm64"
        ;;
        *)
            _err_msg "$(_red "Unsupported architecture: $(uname -m)")"; exit 1
        ;;
    esac

    curl -L "${GITHUB_PROXY}github.com/oneclickvirt/backtrace/releases/download/output/backtrace-${OS_TYPE}-${OS_ARCH}" -o /usr/local/bin/backtrace
    chmod +x /usr/local/bin/backtrace
    if _is_exists "backtrace"; then
        _suc_msg "$(_green "Backtrace Installed Successfully!")"
    else
        _err_msg "$(_red "Backtrace Installed fail.")"; exit 1
    fi
    clear_screen
}

backTrace() {
    clear_screen
    pre_check
    before_run
    backtrace_install
    backtrace
}

backTrace