#!/usr/bin/env sh
#
# Description: This script is used to quickly install a streaming media detection program based on golang reconstruction.
#
# Copyright (c) 2025 honeok <honeok@duck.com>
#
# References:
# https://github.com/HsukqiLee/MediaUnlockTest
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

# https://www.graalvm.org/latest/reference-manual/ruby/UTF8Locale
export LANG=en_US.UTF-8

_red() { printf "\033[91m%s\033[0m\n" "$*"; }
_green() { printf "\033[92m%s\033[0m\n" "$*"; }
_yellow() { printf "\033[93m%s\033[0m\n" "$*"; }
_err_msg() { printf "\033[41m\033[1mError\033[0m %s\n" "$*"; }
_suc_msg() { printf "\033[42m\033[1mSuccess\033[0m %s\n" "$*"; }
_info_msg() { printf "\033[43m\033[1mInfo\033[0m %s\n" "$*"; }

# 各变量默认值
GITHUB_PROXY='https://files.m.daocloud.io/'
UA_BROWSER='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36'

# 用于检查命令是否存在
_is_exists() {
    _CMD="$1"
    if type "$_CMD" >/dev/null 2>&1; then return 0;
    elif command -v "$_CMD" >/dev/null 2>&1; then return 0;
    elif which "$_CMD" >/dev/null 2>&1; then return 0;
    else return 1;
    fi
}

clear_screen() {
    ( [ -t 1 ] && tput clear 2>/dev/null ) || clear
}

pre_check() {
    if [ "$(id -ru)" -ne 0 ]; then
        _err_msg "$(_red 'This script must be run as root!')"; exit 1
    fi
    if [ "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" != "/root" ]; then
        cd /root 2>/dev/null || { _err_msg "$(_red "Failed to change directory, Check permissions and try again!")"; exit 1; }
    fi
    # 境外服务器仅ipv4访问测试通过后取消github代理
    if [ "$(curl --user-agent "$UA_BROWSER" -fsL -m 3 --retry 2 -4 "http://www.qualcomm.cn/cdn-cgi/trace" | grep -i '^loc=' | cut -d'=' -f2 | grep .)" != "CN" ]; then
        unset GITHUB_PROXY
    fi
}

os_check() {
    # 获取操作系统和架构信息
    if [ -f /etc/openwrt_release ]; then
        OS_TYPE="$(uname -s 2>/dev/null | awk '{print tolower($0)}')"
    elif _is_exists "termux-setup-storage" > /dev/null 2>&1; then
        OS_TYPE="android"
    else
        OS_TYPE="$(uname -s 2>/dev/null | sed 's/[A-Z]/\L&/g')"
    fi
}

before_run() {
    [ -f "$HOME/unlock-test" ] && rm -f "$HOME/unlock-test" >/dev/null 2>&1
    [ -f /usr/bin/unlock-test ] && rm -f /usr/bin/unlock-test >/dev/null 2>&1
    [ -f /usr/local/bin/unlock-test ] && rm -f /usr/local/bin/unlock-test >/dev/null 2>&1
}

mediaunlock_install() {
    VERSION="$(curl -fsL --retry 5 "https://api.github.com/repos/HsukqiLee/MediaUnlockTest/releases/latest" | awk -F '["v]' '/tag_name/{print $5}')"
    [ -z "$VERSION" ] && { _err_msg "$(_red "Unable to obtain MediaUnlockTest version!")"; exit 1; }
    case "$(uname -m)" in
        i*86 | x86)
            OS_ARCH="386"
        ;;
        x86_64 | amd64)
            OS_ARCH="amd64"
        ;;
        armv6*)
            OS_ARCH="arm6"
        ;;
        armv7*)
            OS_ARCH="arm7"
        ;;
        armv8* | arm64 | aarch64)
            OS_ARCH="arm64"
        ;;
        ppc64le)
            OS_ARCH="ppc64le"
        ;;
        riscv64)
            OS_ARCH="riscv64"
        ;;
        s390x)
            OS_ARCH="s390x"
        ;;
        *)
            _err_msg "$(_red "Unsupported architecture: $(uname -m)")"; exit 1
        ;;
    esac

    _info_msg "$(_yellow "Downloading MediaUnlockTest Please wait.")"
    curl -L "${GITHUB_PROXY}github.com/HsukqiLee/MediaUnlockTest/releases/download/v${VERSION}/unlock-test_${OS_TYPE}_${OS_ARCH}" -o /usr/local/bin/unlock-test
    chmod +x /usr/local/bin/unlock-test
    if unlock-test -v >/dev/null 2>&1; then
        _suc_msg "$(_green "MediaUnlockTest Installed Successfully!")"
    else
        _err_msg "$(_red "MediaUnlockTest Installed fail.")"; exit 1
    fi
    clear_screen
}

MediaUnlockTest() {
    clear_screen
    pre_check
    os_check
    before_run
    mediaunlock_install
    unlock-test "$@"
}

MediaUnlockTest "$@"