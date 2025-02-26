#!/usr/bin/env bash
#
# Description: A script for quickly installing the latest Docker CE on supported Linux distributions.
# Supported Systems: debian10+ ubuntu20+ centos7+ rhel7+ rocky8+ alma8+ alpine3.20+
#
# Copyright (C) 2023 - 2025 honeok <honeok@duck.com>
#
# References:
# https://docs.docker.com/engine/install
# https://docs.docker.com/reference/cli/dockerd/#daemon-configuration-file
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

# 当前脚本版本号
readonly version='v0.1.2 (2025.02.19)'

yellow='\033[1;33m'
red='\033[1;38;5;160m'
green='\033[1;32m'
cyan='\033[1;36m'
purple='\033[1;35m'
white='\033[0m'
_yellow() { echo -e "${yellow}$*${white}"; }
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }
_cyan() { echo -e "${cyan}$*${white}"; }
_purple() { echo -e "${purple}$*${white}"; }

_err_msg() { echo -e "\033[41m\033[1m警告${white} $*"; }
_suc_msg() { echo -e "\033[42m\033[1m成功${white} $*"; }
_info_msg() { echo -e "\033[43m\033[1;37m提示${white} $*"; }

export DEBIAN_FRONTEND=noninteractive

# https://github.com/koalaman/shellcheck/wiki/SC2155
os_info=$(grep "^PRETTY_NAME=" /etc/*-release | cut -d '"' -f 2 | sed 's/ (.*)//')
os_name=$(grep "^ID=" /etc/*-release | awk -F'=' '{print $2}' | sed 's/"//g')
readonly os_info os_name

getdocker_pid='/tmp/getdocker.pid'
readonly getdocker_pid

trap "cleanup_exit; exit 0" SIGINT SIGQUIT SIGTERM EXIT

cleanup_exit() {
    [ -f "$getdocker_pid" ] && sudo rm -f "$getdocker_pid"
}

if [ -f "$getdocker_pid" ] && kill -0 "$(cat "$getdocker_pid")" 2>/dev/null; then
    exit 1
fi

echo $$ > "$getdocker_pid"

_clear() {
    [ -t 1 ] && tput clear 2>/dev/null || echo -e "\033[2J\033[H" || clear
}

# Logo generation from: https://www.lddgo.net/string/text-to-ascii-art (Small Slant)
_show_logo() {
    local os_text
    os_text="操作系统: $os_info"

    echo -e "${yellow}  _____    __     __        __ 
 / ______ / /____/ ___ ____/ /_____ ____
/ (_ / -_/ __/ _  / _ / __/  '_/ -_/ __/
\___/\__/\__/\_,_/\___\__/_/\_\\__/_/
"

    _green "$os_text"
    _cyan "当前脚本版本: $version 🐳"
}

_show_usage() {
    cat <<EOF
Usage: $0

       Options:        [--install]
                       [--uninstall]

Manual: https://github.com/honeok/cross/blob/master/get-docker.sh

EOF
    exit 1
}

_os_permission() {
    case "$os_name" in
        'debian')
            # 检查是否为Debian Testing或Unstable版本
            if grep -q '/sid' /etc/debian_version; then
                _err_msg "$(_red '不支持Debian Testing和Debian Unstable版本')" && _end_message && exit 1
            fi
            # 检查Debian版本是否小于11
            if [[ "$(grep -oE '[0-9]+' /etc/debian_version | head -1)" -lt "11" ]]; then
                _err_msg "$(_red '此版本的Debian太旧，已不再受支持！')" && _end_message && exit 1
            fi
        ;;
        'ubuntu')
            # 检查Ubuntu版本是否小于20.04
            if [[ "$(grep "^VERSION_ID" /etc/*-release | cut -d '"' -f 2 | tr -d '.')" -lt "2004" ]]; then
                _err_msg "$(_red '此Ubuntu版本已过时且不受支持')" && _end_message && exit 1
            fi
        ;;
        'rhel' | 'centos' | 'rocky' | 'almalinux')
            # 检查RHEL/CentOS/Rocky/AlmaLinux版本是否小于7
            if [[ "$(grep -shoE '[0-9]+' /etc/redhat-release /etc/centos-release /etc/rocky-release /etc/almalinux-release | head -1)" -lt "7" ]]; then
                _err_msg "$(_red "$os_name 9 或更高版本才能使用此安装程序")" && _end_message && exit 1
            fi
        ;;
        'alpine')
            # 检查Alpine版本是否小于3.20
            if [[ "$(echo -e "$(awk -F'.' '{print $1 "." $2}' /etc/alpine-release)\n3.20" | sort -V | head -n 1)" != "3.20" ]]; then
                _err_msg "$(_red "3.20或更高版本才能使用此安装程序")" && _end_message && exit 1
            fi
        ;;
        *)
            # 不支持的操作系统
            _err_msg "$(_red '当前操作系统不被支持！')" && _end_message && exit 1
        ;;
    esac
}

virt_check() {
    local processor_type kernel_logs system_manufacturer system_product_name system_version

    processor_type=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
    kernel_logs=""
    system_manufacturer=""
    system_product_name=""
    system_version=""

    if command -v dmesg >/dev/null 2>&1; then
        kernel_logs=$(dmesg 2>/dev/null)
    fi

    if command -v dmidecode >/dev/null 2>&1; then
        system_manufacturer=$(dmidecode -s system-manufacturer 2>/dev/null)
        system_product_name=$(dmidecode -s system-product-name 2>/dev/null)
        system_version=$(dmidecode -s system-version 2>/dev/null)
    fi

    if grep -qa docker /proc/1/cgroup; then
        virt_type="Docker"
    elif grep -qa lxc /proc/1/cgroup; then
        virt_type="LXC"
    elif grep -qa container=lxc /proc/1/environ; then
        virt_type="LXC"
    elif [[ -f /proc/user_beancounters ]]; then
        virt_type="OpenVZ"
    elif [[ "$kernel_logs" == *kvm-clock* ]]; then
        virt_type="KVM"
    elif [[ "$processor_type" == *KVM* ]]; then
        virt_type="KVM"
    elif [[ "$processor_type" == *QEMU* ]]; then
        virt_type="KVM"
    elif [[ "$kernel_logs" == *"VMware Virtual Platform"* ]]; then
        virt_type="VMware"
    elif [[ "$kernel_logs" == *"Parallels Software International"* ]]; then
        virt_type="Parallels"
    elif [[ "$kernel_logs" == *VirtualBox* ]]; then
        virt_type="VirtualBox"
    elif [[ -e /proc/xen ]]; then
        if grep -q "control_d" "/proc/xen/capabilities" 2>/dev/null; then
            virt_type="Xen-Dom0"
        else
            virt_type="Xen-DomU"
        fi
    elif [ -f "/sys/hypervisor/type" ] && grep -q "xen" "/sys/hypervisor/type"; then
        virt_type="Xen"
    elif [[ "$system_manufacturer" == *"Microsoft Corporation"* ]]; then
        if [[ "$system_product_name" == *"Virtual Machine"* ]]; then
            if [[ "$system_version" == *"7.0"* || "$system_version" == *"Hyper-V" ]]; then
                virt_type="Hyper-V"
            else
                virt_type="Microsoft Virtual Machine"
            fi
        fi
    else
        virt_type="Dedicated"
    fi
}

_virt_permission() {
    virt_check

    if [[ "$virt_type" == "Docker" || "$virt_type" == "LXC" || "$virt_type" == "OpenVZ" ]]; then
        _err_msg "$(_red '当前虚拟化架构不被支持！')"
        _end_message
        exit 1
    fi
}

pkg_remove() {
    if [ "$#" -eq "0" ]; then
        _err_msg "$(_red '未提供软件包参数')"
        return 1
    fi

    check_installed() {
        local package="$1"
        if command -v dnf >/dev/null 2>&1; then
            sudo rpm -q "$package" >/dev/null 2>&1
        elif command -v yum >/dev/null 2>&1; then
            sudo rpm -q "$package" >/dev/null 2>&1
        elif command -v apt >/dev/null 2>&1; then
            sudo dpkg -l | grep -qw "$package"
        elif command -v apt-get >/dev/null 2>&1; then
            sudo dpkg -l | grep -qw "$package"
        elif command -v apk >/dev/null 2>&1; then
            sudo apk info | grep -qw "$package"
        else
            _err_msg "$(_red '未知的包管理器')"
            return 1
        fi
        return 0
    }

    for package in "$@"; do
        _yellow "正在卸载 $package"
        if check_installed "$package"; then
            if command -v dnf >/dev/null 2>&1; then
                sudo dnf remove -y "$package"*
            elif command -v yum >/dev/null 2>&1; then
                sudo yum remove -y "$package"*
            elif command -v apt >/dev/null 2>&1; then
                sudo apt purge -y "$package"*
            elif command -v apt-get >/dev/null 2>&1; then
                sudo apt-get purge -y "$package"*
            elif command -v apk >/dev/null 2>&1; then
                sudo apk del "$package"*
            fi
        else
            _err_msg "$(_red "$package 没有安装，跳过卸载！")"
        fi
    done
}

geo_check() {
    country=$(curl -fskL --connect-timeout 5 http://dash.cloudflare.com/cdn-cgi/trace | grep '^loc=' | cut -d= -f2)

    if [ -z "$country" ]; then
        _err_msg "$(_red '无法获取服务器所在地区，请检查网络后重试！')"
        _end_message
        exit 1
    fi
    readonly country
}

_runtime() {
    local runcount
    runcount=$(curl -fskL -m 2 --retry 2 -o - "https://hit.forvps.gq/https://github.com/honeok/cross/raw/master/get-docker.sh" | grep -m1 -oE "[0-9]+[ ]+/[ ]+[0-9]+")
    today_runcount=$(awk -F ' ' '{print $1}' <<< "$runcount") && total_runcount=$(awk -F ' ' '{print $3}' <<< "$runcount")
}

sudo() {
    if [ "$(id -ru)" -ne 0 ]; then
        if command -v sudo >/dev/null 2>&1; then
            sudo "$@"
        else
            _err_msg "$(_red '您的系统未安装sudo，因此无法进行该项操作')"
            _end_message
            exit 1
        fi
    else
        "$@"
    fi
}

systemctl() {
    local _cmd="$1"
    local service_name="$2"

    # local systemctl_cmd
    systemctl_cmd=$(which systemctl 2>/dev/null)

    if command -v apk >/dev/null 2>&1; then
        sudo service "$service_name" "$_cmd"
    else
        sudo "${systemctl_cmd}" "$_cmd" "$service_name"
    fi
}

_fix_dpkg() {
    pkill -f -15 'apt|dpkg' || pkill -f -9 'apt|dpkg'
    for lockfile in "/var/lib/dpkg/lock" "/var/lib/dpkg/lock-frontend"; do
        [ -f "$lockfile" ] && sudo rm -f "$lockfile" >/dev/null 2>&1
    done
    sudo dpkg --configure -a
}

clean_repo_files() {
    [ -f "/etc/yum.repos.d/docker-ce.repo" ] && sudo rm -f /etc/yum.repos.d/docker-ce.repo 2>/dev/null
    [ -f "/etc/yum.repos.d/docker-ce-staging.repo" ] && sudo rm -f /etc/yum.repos.d/docker-ce-staging.repo 2>/dev/null
    [ -f "/etc/apt/keyrings/docker.asc" ] && sudo rm -f /etc/apt/keyrings/docker.asc 2>/dev/null
    [ -f "/etc/apt/sources.list.d/docker.list" ] && sudo rm -f /etc/apt/sources.list.d/docker.list 2>/dev/null
}

_check_install() {
    if command -v docker >/dev/null 2>&1 || \
        sudo docker --version >/dev/null 2>&1 || \
        sudo docker compose version >/dev/null 2>&1 || \
        command -v docker-compose >/dev/null 2>&1; then
            _err_msg "$(_red 'Docker 已安装，正在退出安装程序！')"
            _end_message
            exit 1
    fi
}

_install() {
    local version_code repo_url gpgkey_url

    geo_check
    clean_repo_files

    _info_msg "$(_yellow '正在安装docker环境！')"
    if [[ "$os_name" == "rocky" || "$os_name" == "almalinux" || "$os_name" == "centos" ]]; then
        pkg_remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine >/dev/null 2>&1

        if [[ "$country" == "CN" ]]; then
            repo_url="https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo"
        else
            repo_url="https://download.docker.com/linux/centos/docker-ce.repo"
        fi

        if command -v dnf >/dev/null 2>&1; then
            if ! sudo dnf config-manager --help >/dev/null 2>&1; then
                sudo dnf install -y dnf-plugins-core
            fi
            sudo dnf config-manager --add-repo "$repo_url" >/dev/null 2>&1
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        elif command -v yum >/dev/null 2>&1; then
            if ! sudo rpm -q yum-utils >/dev/null 2>&1; then
                sudo yum install -y yum-utils
            fi
            sudo yum-config-manager --add-repo "$repo_url" >/dev/null 2>&1
            sudo yum makecache fast
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        else
            _err_msg "$(_red '未知的包管理器！')"
            _end_message
            exit 1
        fi

        systemctl enable docker
        systemctl start docker
    elif [[ "$os_name" == "rhel" ]]; then
        pkg_remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine podman runc >/dev/null 2>&1

        if ! dnf config-manager --help >/dev/null 2>&1; then
            dnf install -y dnf-plugins-core
        fi

        if [[ "$country" == "CN" ]]; then
            sudo dnf config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/rhel/docker-ce.repo
        else
            sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
        fi

        sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        systemctl enable docker
        systemctl start docker
    elif [[ "$os_name" == "debian" || "$os_name" == "ubuntu" ]]; then
        # version_code="$(. /etc/*-release && echo "$VERSION_CODENAME")"
        version_code="$(grep "^VERSION_CODENAME" /etc/*-release | cut -d= -f2)"

        pkg_remove docker.io docker-doc docker-compose podman-docker containerd runc >/dev/null 2>&1

        if [[ "$country" == "CN" ]]; then
            repo_url="https://mirrors.aliyun.com/docker-ce/linux/${os_name}"
            gpgkey_url="https://mirrors.aliyun.com/docker-ce/linux/${os_name}/gpg"
        else
            repo_url="https://download.docker.com/linux/${os_name}"
            gpgkey_url="https://download.docker.com/linux/${os_name}/gpg"
        fi

        _fix_dpkg
        sudo apt-get -qq update
        # sudo apt-get install -y -qq ca-certificates curl apt-transport-https lsb-release gnupg
        sudo apt-get install -y -qq ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL "$gpgkey_url" -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        # add the repository to apt sources
        echo "deb [arch=$(sudo dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] $repo_url $version_code stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        sudo apt-get -qq update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        systemctl enable docker
        systemctl start docker
    elif [[ "$os_name" == "alpine" ]]; then

        #s#old#new#g
        # [[ "$country" == "CN" ]] && sed -i "s#dl-cdn.alpinelinux.org#mirrors.aliyun.com#g" /etc/apk/repositories
        [[ "$country" == "CN" ]] && sed -i -E 's|^https?://dl-cdn.alpinelinux.org|https://mirrors.aliyun.com|g' /etc/apk/repositories

        sudo apk update && sudo apk upgrade
        sudo apk add docker docker-compose
        systemctl enable docker
        systemctl start docker
    else
        _err_msg "$(_red '当前操作系统不被支持！')"
        _end_message
        exit 1
    fi
}

_uninstall() {
    local depend_datadir depend_files bin_files
    depend_datadir=("/var/lib/docker" "/var/lib/containerd" "/etc/docker" "/opt/containerd")
    depend_files=("/etc/yum.repos.d/docker*" "/etc/apt/sources.list.d/docker.*" "/etc/apt/keyrings/docker.*" "/var/log/docker.*")
    bin_files=("/usr/bin/docker" "/usr/bin/docker-compose")

    # 停止并删除Docker服务和容器
    stop_and_remove_docker() {
        local running_containers
        running_containers=$(sudo docker ps -a -q 2>/dev/null)

        if [ -n "$running_containers" ]; then
            sudo docker rm -f "$running_containers" 2>/dev/null || true
        fi
        systemctl stop docker.socket 2>/dev/null
        systemctl stop docker
        systemctl disable docker
    }

    # 移除Docker文件和仓库文件
    cleanup_files() {
        for pattern in "${depend_files[@]}"; do
            for file in $pattern; do
                if [ -e "$file" ]; then
                    sudo rm -f "$file" >/dev/null 2>&1
                fi
            done
        done

        for file in "${depend_datadir[@]}" "${bin_files[@]}"; do
            if [ -e "$file" ]; then
                sudo rm -rf "$file" >/dev/null 2>&1
            fi
        done
    }

    # 检查Docker是否安装
    if ! command -v docker >/dev/null 2>&1; then
        _err_msg "$(_red 'Docker未安装在系统上，无法继续卸载')"
        return 1
    fi

    stop_and_remove_docker
    pkg_remove docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    cleanup_files

    hash -r
    sleep 2

    if command -v docker >/dev/null 2>&1 || [ -e "/usr/bin/docker" ]; then
        _err_msg "$(_red 'Docker卸载失败，请手动检查！')"
        return 1
    else
        _suc_msg "$(_green 'Docker和Docker Compose已卸载，并清理文件夹和相关依赖')"
    fi
}

_version() {
    local docker_v=""
    local docker_compose_v=""

    # 获取Docker版本
    if command -v docker >/dev/null 2>&1; then
        docker_v=$(sudo docker --version | awk -F '[ ,]' '{print $3}')
    elif command -v docker.io >/dev/null 2>&1; then
        docker_v=$(sudo docker.io --version | awk -F '[ ,]' '{print $3}')
    fi

    # 获取Docker Compose版本
    if docker compose version >/dev/null 2>&1; then
        docker_compose_v=$(sudo docker compose version --short)
    elif command -v docker-compose >/dev/null 2>&1; then
        docker_compose_v=$(sudo docker-compose version --short)
    fi

    echo
    echo "Docker版本: v${docker_v}"
    echo "Docker Compose版本: v${docker_compose_v}"
    echo
    _yellow "获取Docker信息"
    sleep 2
    sudo docker version 2>/dev/null

    # intentionally mixed spaces and tabs here -- tabs are stripped by "<<-EOF", spaces are kept in the output
    echo
    echo "================================================================================"
    echo
    echo "To run the Docker daemon as a fully privileged service, but granting non-root"
    echo "users access, refer to https://docs.docker.com/go/daemon-access/"
    echo
    echo "WARNING: Access to the remote API on a privileged Docker daemon is equivalent"
    echo "         to root access on the host. Refer to the 'Docker daemon attack surface'"
    echo "         documentation for details: https://docs.docker.com/go/attack-surface/"
    echo
    echo "================================================================================"
    echo
}

_status() {
    if sudo "${systemctl_cmd}" is-active --quiet docker || \
        sudo docker info >/dev/null 2>&1 || \
        sudo /etc/init.d/docker status | grep -q 'started' || \
        sudo service docker status >/dev/null 2>&1 || \
        curl -s --unix-socket /var/run/docker.sock http://localhost/version >/dev/null 2>&1; then
            _suc_msg "$(_green 'Docker已完成自检，启动并设置开机自启！')"
    else
        _err_msg "$(_red 'Docker状态检查失败或服务无法启动，请检查安装日志或手动启动Docker服务')"
        _end_message
        exit 1
    fi
}

_end_message() {
    local current_time current_timezone message_time

    _runtime

    current_time=$(date '+%Y-%m-%d %H:%M:%S')
    current_timezone=$(date +"%Z %z")

    # https://github.com/koalaman/shellcheck/issues/3093
    message_time="服务器当前时间: ${current_time} 时区: ${current_timezone} 脚本执行完成"
    printf "\033[1;32m%s\033[0m\n" "$message_time"
    _purple "感谢使用本脚本！如有疑问，请访问 https://www.honeok.com 获取更多信息"
    _yellow "脚本当天运行次数: ${today_runcount} 累计运行次数: ${total_runcount}"
}

docker_install() {
    _clear
    _show_logo
    _os_permission
    _virt_permission
    _check_install
    _install
    _version
    _status
    _end_message
}

docker_uninstall() {
    _clear
    _show_logo
    _os_permission
    _virt_permission
    _uninstall
    _end_message
}

if [ "$#" -eq 0 ]; then
    docker_install
else
    while [[ "$#" -ge 1 ]]; do
        case "$1" in
            --install)
                docker_install
                shift 1
            ;;
            --uninstall)
                docker_uninstall
                shift 1
            ;;
            *)
                _err_msg "$(_red "无效选项, 当前参数${1}不被支持！")" 
                _end_message
                _show_usage
            ;;
        esac
    done
fi