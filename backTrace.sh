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

red='\033[91m'
cyan='\033[96m'
white='\033[0m'
_red() { printf "$red%s$white" "$*"; }
_cyan() { printf "$cyan%s$white" "$*"; }

_err_msg() { printf "\033[41m\033[1mError$white %s\n" "$*"; }

# 各变量默认值
github_proxy='https://gh-proxy.com/'

os_type=$(uname -s 2>/dev/null | sed 's/[A-Z]/\L&/g')
os_arch=$(uname -m 2>/dev/null | sed 's/[A-Z]/\L&/g')
readonly os_type os_arch

# 清屏函数
clear_screen() {
    if [ -t 1 ]; then
        tput clear 2>/dev/null || echo -e "\033[2J\033[H" || clear
    fi
}

pre_check() {
    if [ "$(id -ru)" -ne 0 ] || [ "$EUID" -ne 0 ]; then
        _err_msg "$(_red 'This script must be run as root!')" && exit 1
    fi
    if [ "$(ps -p $$ -o comm=)" != "bash" ] || readlink /proc/$$/exe | grep -q "dash"; then
        _err_msg "$(_red 'This script needs to be run with bash, not sh!')" && exit 1
    fi
    if [ "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" != "/root" ]; then
        cd /root 2>/dev/null || { _err_msg "$(_red 'Failed to change directory, Check permissions and try again!')" && exit 1; }
    fi
    if [ "$(curl -fskL -m 5 -4 "https://www.qualcomm.cn/cdn-cgi/trace" | grep -i '^loc=' | cut -d'=' -f2 | xargs)" != "CN" ]; then
        unset github_proxy
    fi
}

backtrace_uninstall() {
    [ -f "$HOME/backtrace" ] && rm -f "$HOME/backtrace" 2>/dev/null
    [ -f /usr/bin/backtrace ] && rm -f /usr/bin/backtrace 2>/dev/null
    [ -f /usr/local/bin/backtrace ] && rm -f /usr/local/bin/backtrace 2>/dev/null
}

backtrace_install() {
    local arch_suffix

    # 定义支持的操作系统和架构
    case "$os_type" in
        'linux' | 'darwin' | 'freebsd' | 'openbsd') : ;;
        *) _err_msg "$(_red 'Unsupported operating system:') $(_cyan "$os_type")" && exit 1 ;;
    esac
    case "$os_arch" in
        'x86_64' | 'x86' | 'amd64' | 'x64') arch_suffix="amd64" ;;
        'i386' | 'i686') arch_suffix="386" ;;
        'armv7l' | 'armv8' | 'armv8l' | 'aarch64' | 'arm64') arch_suffix="arm64" ;;
        *) _err_msg "$(_red 'Unsupported architecture:') $(_cyan "$os_arch")" && exit 1 ;;
    esac

    curl -fskL -o backtrace "${github_proxy}https://github.com/oneclickvirt/backtrace/releases/download/output/backtrace-${os_type}-${arch_suffix}" || { _err_msg "$(_red 'Download backtrace failed, Check network and try again!')" && exit 1; }
    chmod +x backtrace && mv -f backtrace /usr/local/bin/backtrace && backtrace
}

backTrace() {
    clear_screen
    pre_check
    backtrace_uninstall
    backtrace_install
}

backTrace