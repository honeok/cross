#!/usr/bin/env bash
#
# Description: test the routing of the three major network return lines on the server side.
#
# Original Project: https://github.com/oneclickvirt/backtrace
# Forked and Modified By: honeok <honeok@duck.com>
#
# Archive on GitHub: https://github.com/honeok/archive/raw/master/cross/backtrace.sh

red='\033[31m'
white='\033[0m'
_red() { echo -e ${red}$@${white}; }
_err_msg() { echo -e "\033[41m\033[1mwarn${white} $@"; }

os_type=$(uname -s | sed 's/[A-Z]/\L&/g')
os_arch=$(uname -m | sed 's/[A-Z]/\L&/g')

[ "$(id -u)" -ne "0" ] && exit 1

if [ "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" != "/root" ]; then
    cd /root >/dev/null 2>&1
fi

if [ -f /usr/bin/backtrace ] || command -v backtrace >/dev/null 2>&1; then
    rm -f /usr/bin/backtrace >/dev/null 2>&1
fi

cdn_check() {
    local cloudflare_api="https://dash.cloudflare.com/cdn-cgi/trace"
    local user_agent="Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0"

    country=$(curl -A "$user_agent" -m 10 -s "$cloudflare_api" | sed -n 's/.*loc=\([^ ]*\).*/\1/p')
    [ -z "$country" ] && _err_msg "$(_red 'Failed to obtain the server location. Please check your network connection!')" && exit 1

    if [[ "$country" == "CN" || $(curl -fsL -o /dev/null -w "%{time_total}" --max-time 5 https://raw.githubusercontent.com/honeok/cross/master/README.md) > 3 ]]; then
        github_proxy="https://gh-proxy.com/"
    else
        github_proxy=""
    fi
}

cdn_check

case $os_type in
    [Ll][Ii][Nn][Uu][Xx]|[Dd][Aa][Rr][Ww][Ii][Nn]|[Ff][Rr][Ee][Bb][Ss][Dd]|[Oo][Pp][Ee][Nn][Bb][Ss][Dd])
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