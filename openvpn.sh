#!/usr/bin/env bash
#
# Description: An automated OpenVPN installation script for quick and easy setup on supported systems.
# Supported Systems: debian 11+ ubuntu 22+ centOS 9+ rhel 9+ rocky 9+ alma 9+
#
# Copyright (C) 2025 honeok <honeok@duck.com>
# Copyright (C) 2013 Nyr. Released under the MIT License.
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

# shellcheck disable=SC2034

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

red='\033[91m'
green='\033[92m'
yellow='\033[93m'
white='\033[0m'
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }
_yellow() { echo -e "${yellow}$*${white}"; }

_err_msg() { echo -e "\033[41m\033[1mwarn${white} $*"; }
_suc_msg() { echo -e "\033[42m\033[1msuccess${white} $*"; }
_info_msg() { echo -e "\033[43m\033[1mtip${white} $*"; }

# 预定义常量
os_name=$(grep "^ID=" /etc/*-release | awk -F'=' '{print $2}' | sed 's/"//g')
openvpn_conf="/etc/openvpn/server/server.conf"
readonly os_name openvpn_conf

# 预定义变量
github_Proxy='https://gh-proxy.com/'

# 定义一个数组存储用户未安装的软件包
declare -a uninstall_depend_pkg=()

_exit() {
    local return_value=$?

    if [ ${#uninstall_depend_pkg[@]} -gt 0 ]; then
        (for pkg in "${uninstall_depend_pkg[@]}"; do pkg_uninstall "$pkg" >/dev/null 2>&1; done) & disown
    fi
    exit "$return_value"
}

# 终止信号捕获
trap "_exit" SIGINT SIGQUIT SIGTERM EXIT

# 用于判断命令是否存在
_exists() {
    local cmd="$1"
    if type "$cmd" >/dev/null 2>&1; then
        return 0
    elif command -v "$cmd" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 运行前环境校验
pre_check() {
    local install_depend_pkg
    install_depend_pkg=( "curl" )

    cloudflare_api='www.qualcomm.cn/cdn-cgi/trace'
    UA_BROWSER="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"

    if [ "$(id -ru)" -ne "0" ] || [ "$EUID" -ne "0" ]; then
        _err_msg "$(_red 'This installer needs to be run with superuser privileges!')" && exit 1
    fi
    if [ "$(ps -p $$ -o comm=)" != "bash" ] || readlink /proc/$$/exe | grep -q "dash"; then
        _err_msg "$(_red 'This script needs to be run with bash, not sh!')" && exit 1
    fi
    # 检验运行时必备的软件包
    for pkg in "${install_depend_pkg[@]}"; do
        if ! _exists "$pkg" >/dev/null 2>&1; then
            uninstall_depend_pkg+=("$pkg")
            pkg_install "$pkg"
        fi
    done
    # 内核版本校验
    if [ "$(uname -r | cut -d "." -f 1)" -eq 2 ]; then
        _err_msg "$(_red 'The system is running an old kernel, which is incompatible with this installer.')" && exit 1
    fi

    # 获取IP地址
    ipv4_address=$(curl -A "$UA_BROWSER" -fskL -m 3 -4 "$cloudflare_api" | grep -i '^ip=' | cut -d'=' -f2 | xargs)
    ipv6_address=$(curl -A "$UA_BROWSER" -fskL -m 3 -6 "$cloudflare_api" | grep -i '^ip=' | cut -d'=' -f2 | xargs)
    # 获取服务器地区
    loc=$(curl -A "$UA_BROWSER" -fskL -m 3 "$cloudflare_api" | grep '^loc=' | cut -d'=' -f2 | xargs)
    # 境外服务器仅ipv4访问测试通过后取消github代理
    if [ -n "$ipv4_address" ] && [ "$loc" != "CN" ]; then
        github_Proxy=''
    fi
}

pkg_install() {
    for package in "$@"; do
        _yellow "Installing $package"
        if _exists dnf; then
            dnf install -y "$package"
        elif _exists yum; then
            yum install -y "$package"
        elif _exists apt; then
            DEBIAN_FRONTEND=noninteractive apt install -y -q "$package"
        elif _exists apt-get; then
            DEBIAN_FRONTEND=noninteractive apt-get install -y -q "$package"
        elif _exists pacman; then
            pacman -S --noconfirm --needed "$package"
        elif _exists zypper; then
            zypper install -y "$package"
        fi
    done
}

pkg_uninstall() {
    for package in "$@"; do
        if _exists dnf; then
            dnf remove -y "$package"
        elif _exists yum; then
            yum remove -y "$package"
        elif _exists apt; then
            apt purge -y "$package"
        elif _exists apt-get; then
            apt-get purge -y "$package"
        elif _exists pacman; then
            pacman -Rns --noconfirm "$package"
        elif _exists zypper; then
            zypper remove -y "$package"
        fi
    done
}

# 系统校验
check_os_ver() {
    case "$os_name" in
        'debian')
            os="debian"
            os_version=$(grep -oE '[0-9]+' /etc/debian_version | head -1)
            group_name="nogroup"
            if grep -q '/sid' /etc/debian_version; then
                _err_msg "$(_red 'Debian Testing and Debian Unstable are not supported by this installer.')" && exit 1
            fi
            if [ "$os_version" -lt 10 ]; then
                _err_msg "$(_red 'Debian 10 or higher is required to use this installer.')" && exit 1
            fi
        ;;
        'ubuntu')
            os="ubuntu"
            os_version=$(grep "^VERSION_ID" /etc/*-release | cut -d '"' -f 2 | tr -d '.')
            group_name="nogroup"
            if [ "$os_version" -lt "2004" ]; then
                _err_msg "$(_red 'Ubuntu 20.04 or higher is required to use this installer.')" && exit 1
            fi
        ;;
        'almalinux' | 'centos' | 'rhel' | 'rocky')
            os="centos"
            os_version=$(grep -shoE '[0-9]+' /etc/redhat-release /etc/centos-release /etc/rocky-release /etc/almalinux-release | head -1)
            group_name="nobody"
            if [ "$os_version" -lt "7" ]; then
                _err_msg "$(_red "$os_name 7 or higher is required to use this installer.")" && exit 1
            fi
        ;;
        'fedora')
            os="fedora"
            os_version=$(grep -oE '[0-9]+' /etc/fedora-release | head -1)
            group_name="nobody"
        ;;
        'opensuse')
            os="openSUSE"
            os_version=$(tail -1 /etc/SUSE-brand | grep -oE '[0-9\\.]+')
            group_name="nogroup"
        ;;
        *)
            _err_msg "$(_red 'This installer seems to be running on an unsupported distribution.')" && exit 1
        ;;
    esac
}

# 检查tun设备是否可用
check_tun() {
    if [ ! -e /dev/net/tun ] || ! (exec 7<>/dev/net/tun) 2>/dev/null; then
        _err_msg "$(_red 'The system does not have the TUN device available.')" && exit 1
    fi
}

ovpn() {
    pre_check
    check_os_ver
    check_tun
}

ovpn