#!/usr/bin/env bash
#
# Description: Test the routing of the three major network return lines on the server side.
#
# Forked and Modified By: Copyright (C) 2024 - 2025 honeok <honeok@duck.com>
#
# Original Project: https://github.com/oneclickvirt/backtrace
#
# https://github.com/honeok/cross/raw/master/backTrace.sh
#
# License Information:
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License, version 3 or later.
#
# This program is distributed WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <https://www.gnu.org/licenses/>.

# shellcheck disable=SC2164

red='\033[31m'
white='\033[0m'
_red() { echo -e "${red}$*${white}"; }

_err_msg() { echo -e "\033[41m\033[1mwarn${white} $*"; }

os_type=$(uname -s 2>/dev/null | sed 's/[A-Z]/\L&/g' || echo 'unknown')
os_arch=$(uname -m 2>/dev/null | sed 's/[A-Z]/\L&/g' || echo 'unknown')

[ "$(id -u)" -ne "0" ] && _err_msg "$(_red 'This script must be run as root!')" && exit 1

if [ "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" != "/root" ]; then
    cd /root >/dev/null 2>&1 || _err_msg "$(_red 'Failed to change directory. Check permissions and try again!')" && exit 1
fi

uninstall() {
    [ -f "$HOME/backtrace" ] && rm -f "$HOME/backtrace" >/dev/null 2>&1
    [ -f /usr/bin/backtrace ] && rm -f /usr/bin/backtrace >/dev/null 2>&1
}

pre_check() {
    local cloudflare_api ipinfo_api ipsb_api

    uninstall

    cloudflare_api=$(curl -sL -m 10 -A "Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0" "https://dash.cloudflare.com/cdn-cgi/trace" | sed -n 's/.*loc=\([^ ]*\).*/\1/p')
    ipinfo_api=$(curl -sL --connect-timeout 5 https://ipinfo.io/country)
    ipsb_api=$(curl -sL --connect-timeout 5 -A Mozilla https://api.ip.sb/geoip | sed -n 's/.*"country_code":"\([^"]*\)".*/\1/p')

    for api in "$cloudflare_api" "$ipinfo_api" "$ipsb_api"; do
        if [ -n "$api" ]; then
            country="$api"
            break
        fi
    done

    if [[ -z "$country" ]]; then
        _err_msg "$(_red 'Failed to obtain the server location. Please check your network connection!')"
        exit 1
    fi

    if [[ "$country" == "CN" || $(curl -fsL -o /dev/null -w "%{time_total}" --max-time 5 https://github.com/honeok/cross/raw/master/README.md) -gt 3 ]]; then
        github_proxy="https://gh-proxy.com/"
    else
        github_proxy=""
    fi
}

exec_backtrace() {
    case $os_type in
        [Ll][Ii][Nn][Uu][Xx]|[Dd][Aa][Rr][Ww][Ii][Nn]|[Ff][Rr][Ee][Ee][Bb][Ss][Dd]|[Oo][Pp][Ee][Nn][Bb][Ss][Dd])
            case $os_arch in
                [Xx]86_64|[Xx][86]|[Aa][Mm][Dd]64|[Xx]64)
                    curl -sL -o backtrace "${github_proxy}https://github.com/oneclickvirt/backtrace/releases/download/output/backtrace-${os_type}-amd64"
                    ;;
                [Ii]386|[Ii]686)
                    curl -sL -o backtrace "${github_proxy}https://github.com/oneclickvirt/backtrace/releases/download/output/backtrace-${os_type}-386"
                    ;;
                [Aa][Rr][Mm][Vv]7l|[Aa][Rr][Mm][Vv]8|[Aa][Rr][Mm][Vv]8l|[Aa][Aa][Rr][Cc][Hh]64|[Aa][Rr][Mm]64)
                    curl -sL -o backtrace "${github_proxy}https://github.com/oneclickvirt/backtrace/releases/download/output/backtrace-${os_type}-arm64"
                    ;;
                *)
                    _err_msg "$(_red "Unsupported architecture: $os_arch")"
                    exit 1
                    ;;
            esac
            ;;
        *)
            _err_msg "$(_red "Unsupported operating system: $os_type")"
            exit 1
            ;;
    esac
    chmod +x backtrace && cp backtrace /usr/bin/backtrace && rm -f backtrace && backtrace
}

pre_check
exec_backtrace

for arg in "$@"; do
    case $arg in
        -d)
            uninstall
            exit 0
            ;;
        *)
            _err_msg "$(_red 'Invalid option, Please try again!')"
            exit 1
            ;;
    esac
done