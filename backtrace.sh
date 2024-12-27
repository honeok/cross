#!/usr/bin/env bash
#
# Description: Three network return routing line testing.
#
# From: https://github.com/oneclickvirt/backtrace
# Modify by: honeok <honeok@duck.com>
#
# Archive on GitHub: https://github.com/honeok/archive/raw/master/cross/backtrace.sh

red='\033[31m'
white='\033[0m'
_red() { echo -e ${red}$@${white}; }
_err_msg() { echo -e "\033[41m\033[1m警告${white} $@"; }

os_type=$(uname -s | sed 's/[A-Z]/\L&/g')
os_arch=$(uname -m | sed 's/[A-Z]/\L&/g')

[ "$(id -u)" -ne "0" ] && exit 1

if [ "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" != "/root" ]; then
    cd /root >/dev/null 2>&1
fi

[ -f /usr/bin/backtrace ] && rm -rf /usr/bin/backtrace >/dev/null 2>&1

geo_check() {
    local cloudflare_api="https://dash.cloudflare.com/cdn-cgi/trace"
    local user_agent="Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0"

    country=$(curl -A "$user_agent" -m 10 -s "$cloudflare_api" | sed -n 's/.*loc=\([^ ]*\).*/\1/p')
    [ -z "$country" ] && _err_msg "$(_red '无法获取服务器所在地区，请检查网络！')" && exit 1
}

cdn_check() {
    geo_check
    if [[ "$country" == "CN" || $(curl -fsL -o /dev/null -w "%{time_total}" --max-time 5 https://raw.githubusercontent.com/honeok/Tools/master/README.md) > 3 ]]; then
        github_proxy="https://gh-proxy.com/"
    else
        github_proxy=""
    fi
}

cdn_check

case $os_type in
    linux)
        case $os_arch in
            "x86_64" | "x86" | "amd64" | "x64")
                curl -sL -o backtrace "${github_proxy}https://github.com/oneclickvirt/backtrace/releases/download/output/backtrace-linux-amd64"
                ;;
            "i386" | "i686")
                curl -sL -o backtrace "${github_proxy}https://github.com/oneclickvirt/backtrace/releases/download/output/backtrace-linux-386"
                ;;
            "armv7l" | "armv8" | "armv8l" | "aarch64" | "arm64")
                curl -sL -o backtrace "${github_proxy}https://github.com/oneclickvirt/backtrace/releases/download/output/backtrace-linux-arm64"
                ;;
            *)
                echo "Unsupported architecture: $os_arch"
                exit 1
                ;;
        esac
        ;;
    darwin)
        case $os_arch in
            "x86_64" | "x86" | "amd64" | "x64")
                curl -sL -o backtrace "${github_proxy}https://github.com/oneclickvirt/backtrace/releases/download/output/backtrace-darwin-amd64"
                ;;
            "i386" | "i686")
                curl -sL -o backtrace "${github_proxy}https://github.com/oneclickvirt/backtrace/releases/download/output/backtrace-darwin-386"
                ;;
            "armv7l" | "armv8" | "armv8l" | "aarch64" | "arm64")
                curl -sL -o backtrace "${github_proxy}https://github.com/oneclickvirt/backtrace/releases/download/output/backtrace-darwin-arm64"
                ;;
            *)
                echo "Unsupported architecture: $os_arch"
                exit 1
                ;;
        esac
        ;;
    freebsd)
        case $os_arch in
            amd64)
                curl -sL -o backtrace "${github_proxy}https://github.com/oneclickvirt/backtrace/releases/download/output/backtrace-freebsd-amd64"
                ;;
            "i386" | "i686")
                curl -sL -o backtrace "${github_proxy}https://github.com/oneclickvirt/backtrace/releases/download/output/backtrace-freebsd-386"
                ;;
            "armv7l" | "armv8" | "armv8l" | "aarch64" | "arm64")
                curl -sL -o backtrace "${github_proxy}https://github.com/oneclickvirt/backtrace/releases/download/output/backtrace-freebsd-arm64"
                ;;
            *)
                echo "Unsupported architecture: $os_arch"
                exit 1
                ;;
        esac
        ;;
    openbsd)
        case $os_arch in
            amd64)
                curl -sL -o backtrace "${github_proxy}https://github.com/oneclickvirt/backtrace/releases/download/output/backtrace-openbsd-amd64"
                ;;
            "i386" | "i686")
                curl -sL -o backtrace "${github_proxy}https://github.com/oneclickvirt/backtrace/releases/download/output/backtrace-openbsd-386"
                ;;
            "armv7l" | "armv8" | "armv8l" | "aarch64" | "arm64")
                curl -sL -o backtrace "${github_proxy}https://github.com/oneclickvirt/backtrace/releases/download/output/backtrace-openbsd-arm64"
                ;;
            *)
                echo "Unsupported architecture: $os_arch"
                exit 1
                ;;
        esac
        ;;
    *)
        echo "Unsupported operating system: $os_type"
        exit 1
        ;;
esac

chmod +x backtrace && cp backtrace /usr/bin/backtrace && rm -f backtrace && backtrace