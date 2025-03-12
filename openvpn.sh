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

# shellcheck disable=all

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

reading() { read -rep "$(_yellow "$1")" "$2"; }

# 预定义常量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
UA_BROWSER='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36'
os_name=$(grep "^ID=" /etc/*-release | awk -F'=' '{print $2}' | sed 's/"//g')
readonly SCRIPT_DIR UA_BROWSER os_name

# 预定义变量
github_Proxy='https://gh-proxy.com/'

# 定义一个数组存储用户未安装的软件包
declare -a uninstall_depend_pkg=()

_exit() {
    local return_value="$?"

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
    cloudflare_api='www.qualcomm.cn/cdn-cgi/trace'

    if [ "$(id -ru)" -ne "0" ] || [ "$EUID" -ne "0" ]; then
        _err_msg "$(_red 'This installer needs to be run with superuser privileges!')" && exit 1
    fi
    if [ "$(ps -p $$ -o comm=)" != "bash" ] || readlink /proc/$$/exe | grep -q "dash"; then
        _err_msg "$(_red 'This script needs to be run with bash, not sh!')" && exit 1
    fi

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

# 客户端配置文件生成
generate_client() {
    {
        cat /etc/openvpn/server/client-common.txt
        echo "<ca>"
        cat /etc/openvpn/server/easy-rsa/pki/ca.crt
        echo "</ca>"
        echo "<cert>"
        sed -ne '/BEGIN CERTIFICATE/,$ p' /etc/openvpn/server/easy-rsa/pki/issued/"$client".crt
        echo "</cert>"
        echo "<key>"
        cat /etc/openvpn/server/easy-rsa/pki/private/"$client".key
        echo "</key>"
        echo "<tls-crypt>"
        sed -ne '/BEGIN OpenVPN Static key/,$ p' /etc/openvpn/server/tc.key
        echo "</tls-crypt>"
    } > "$SCRIPT_DIR/$client.ovpn"
}

# 验证输入的字符串是否是有效的IPv4地址
check_ip() {
    printf '%s' "$1" | tr -d '\n' | grep -Eq '^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$'
}

# ipv4合法性检测
detect_ipv4() {
    local ip_match ip_count choose

    # 匹配公网标记 0: 未匹配 1: 成功匹配
    [ -n "$ipv4_address" ] && ip_match=1 || ip_match=0

    # 如果系统中只有一个ipv4地址, 自动选择
    if [ "$(ip -4 addr | grep inet | grep -vEc '127(\.[0-9]{1,3}){3}')" -eq 1 ]; then
        choose_ip=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}')
    else
        # 获取外网默认出站路由
        choose_ip=$(ip -4 route get 1 | sed 's/ uid .*//' | awk '{print $NF;exit}' 2>/dev/null)
        if ! check_ip "$choose_ip"; then
            if [ "$ip_match" = 1 ]; then
                while IFS= read -r line; do
                    [ "$line" = "$ipv4_address" ] && choose_ip="$line"
                done < <(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}')
            fi
            if [ "$ip_match" = 0 ]; then
                printf "\n"
                _info_msg "$(_yellow 'Which IPv4 address should be used?')"
                ip_count=$(ip -4 addr | grep inet | grep -vEc '127(\.[0-9]{1,3}){3}')
                ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | nl -s ') '
                while true; do
                    reading 'IPv4 address [1]: ' option
                    [ -z "$option" ] && option="1"
                    echo "$option" | grep -qE '^[0-9]+$' && [ "$option" -le "$ip_count" ] && break
                    echo "$option: invalid selection."
                done
                # 根据用户选择的编号取出对应ip
                choose_ip=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | sed -n "$option"p)
            fi
        fi
    fi
    if ! check_ip "$choose_ip"; then
        _err_msg "$(_red "Could not detect this server's IP address.")" && exit 1
    fi
}

install_ovpn() {
    
    _yellow 'Welcome to this OpenVPN road warrior installer!'

}

ovpn() {
    pre_check
    check_os_ver
    check_tun
    detect_ipv4
}

ovpn