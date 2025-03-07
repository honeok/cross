#!/usr/bin/env bash
#
# Description: Test the routing of the three major network return lines on the server side.
#
# Copyright (C) 2024 - 2025 honeok <honeok@duck.com>
#
# Based: https://github.com/oneclickvirt/backtrace
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

set \
    -o nounset

red='\033[91m'
white='\033[0m'
_red() { echo -e "${red}$*${white}"; }

_err_msg() { echo -e "\033[41m\033[1mwarn${white} $*"; }

# 预定义常量
github_Proxy='https://gh-proxy.com/'

os_type=$(uname -s 2>/dev/null | sed 's/[A-Z]/\L&/g')
os_arch=$(uname -m 2>/dev/null | sed 's/[A-Z]/\L&/g')
readonly os_type os_arch

pre_runcheck() {
    if [ "$(id -ru)" -ne "0" ] || [ "$EUID" -ne "0" ]; then
        _err_msg "$(_red 'Error: This script must be run as root!')" && exit 1
    fi
    if [ "$(ps -p $$ -o comm=)" != "bash" ] || readlink /proc/$$/exe | grep -q "dash"; then
        _err_msg "$(_red 'Error: This script needs to be run with bash, not sh!')" && exit 1
    fi
    if [ "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" != "/root" ]; then
        cd /root >/dev/null 2>&1 || { _err_msg "$(_red 'Error: Failed to change directory. Check permissions and try again!')" && exit 1; }
    fi
    if [ "$(curl -skL -m 3 -4 "https://www.qualcomm.cn/cdn-cgi/trace" | grep -i '^loc=' | cut -d'=' -f2 | xargs)" != "CN" ]; then
        github_Proxy=''
    fi
}

backtrace_uninstall() {
    [ -f "$HOME/backtrace" ] && rm -f "$HOME/backtrace" 2>/dev/null
    [ -f /usr/bin/backtrace ] && rm -f /usr/bin/backtrace 2>/dev/null
    [ -f /usr/local/bin/backtrace ] && rm -f /usr/local/bin/backtrace 2>/dev/null
}

backtrace_install() {
    local arch_suffix download_Url

    # 定义支持的操作系统和架构
    case "$os_type" in
        'linux' | 'darwin' | 'freebsd' | 'openbsd')
        ;;
        *)
            _err_msg "$(_red "Unsupported operating system: $os_type")" && exit 1
        ;;
    esac

    case "$os_arch" in
        'x86_64' | 'x86' | 'amd64' | 'x64') arch_suffix="amd64" ;;
        'i386' | 'i686') arch_suffix="386" ;;
        'armv7l' | 'armv8' | 'armv8l' | 'aarch64' | 'arm64') arch_suffix="arm64" ;;
        *)
            _err_msg "$(_red "Unsupported architecture: $os_arch")" && exit 1
        ;;
    esac

    download_Url="${github_Proxy}https://github.com/oneclickvirt/backtrace/releases/download/output/backtrace-${os_type}-${arch_suffix}"
    curl -fskL -o backtrace "$download_Url" || { _err_msg "$(_red "Error: Download backtrace failed, Check network and try again!")" && exit 1; }
    chmod +x backtrace && mv -f backtrace /usr/local/bin/backtrace && backtrace
}

_backTrace() {
    pre_runcheck
    backtrace_uninstall
    backtrace_install
}

_backTrace