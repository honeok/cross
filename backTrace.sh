#!/usr/bin/env bash
#
# Description: Test the routing of the three major network return lines on the server side.
#
# Copyright (C) 2024 - 2025 honeok <honeok@duck.com>
#
# Based on: https://github.com/oneclickvirt/backtrace
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

red='\033[31m'
white='\033[0m'
_red() { echo -e "${red}$*${white}"; }

_err_msg() { echo -e "\033[41m\033[1mWARN${white} $*"; }

os_type=$(uname -s 2>/dev/null | sed 's/[A-Z]/\L&/g' || echo 'unknown')
os_arch=$(uname -m 2>/dev/null | sed 's/[A-Z]/\L&/g' || echo 'unknown')

if [ "$(id -u)" -ne "0" ]; then
    _err_msg "$(_red 'This script must be run as root!')" && exit 1
fi
if [ "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" != "/root" ]; then
    cd /root >/dev/null 2>&1 || _err_msg "$(_red 'Failed to change directory. Check permissions and try again!')" && exit 1
fi

uninstall() {
    [ -f "$HOME/backtrace" ] && rm -f "$HOME/backtrace" 2>/dev/null
    [ -f /usr/bin/backtrace ] && rm -f /usr/bin/backtrace 2>/dev/null
    [ -f /usr/local/bin/backtrace ] && rm -f /usr/local/bin/backtrace 2>/dev/null
}

cdn_check() {
    country=$(curl -fskL -m 5 --connect-timeout 5 https://ipinfo.io/country)

    if [ -z "$country" ]; then
        _err_msg "$(_red 'Failed to obtain the server location. Please check your network connection!')"
        _end_message
        exit 1
    fi
    readonly country

    if [[ "$country" == "CN" || \
        $(curl -fskL -o /dev/null -w "%{time_total}" -m 5 https://github.com/honeok/cross/raw/master/README.md | awk '{if ($1 > 3) print 1; else print 0}') -eq 1 ]]; then
        github_proxy="https://gh-proxy.com/"
    else
        github_proxy=""
    fi
}

run_backtrace() {
    case "$os_type" in
        linux | darwin | freebsd | openbsd)
            case "$os_arch" in
                x86_64 | x86 | amd64 | x64)
                    curl -fskL -o backtrace "${github_proxy}https://github.com/oneclickvirt/backtrace/releases/download/output/backtrace-${os_type}-amd64"
                ;;
                i386 | i686)
                    curl -fskL -o backtrace "${github_proxy}https://github.com/oneclickvirt/backtrace/releases/download/output/backtrace-${os_type}-386"
                ;;
                armv7l | armv8 | armv8l | aarch64 | arm64)
                    curl -fskL -o backtrace "${github_proxy}https://github.com/oneclickvirt/backtrace/releases/download/output/backtrace-${os_type}-arm64"
                ;;
                *)
                    _err_msg "$(_red "Unsupported architecture: $os_arch")" && exit 1
                ;;
            esac
        ;;
        *)
            _err_msg "$(_red "Unsupported operating system: $os_type")" && exit 1
        ;;
    esac
    chmod +x backtrace && mv -f backtrace /usr/local/bin/backtrace && backtrace
}

uninstall
cdn_check
run_backtrace