#!/usr/bin/env bash
#
# Description: Used for quickly installing the latest Docker CE on supported Linux distributions
# System Required:  debian11+ ubuntu20+ centos7+ rhel8+ rocky8+ alma8+ alpine3.19+
#
# Copyright (C) 2023 - 2025 honeok <honeok@duck.com>
#
# https://www.honeok.com
# https://github.com/honeok/cross/raw/master/get-docker.sh
#
# Reference:
# https://docs.docker.com/engine/install
#               __      __             __             
#   ___ _ ___  / /_ ___/ / ___  ____  / /__ ___   ____
#  / _ `// -_)/ __// _  / / _ \/ __/ /  '_// -_) / __/
#  \_, / \__/ \__/ \_,_/  \___/\__/ /_/\_\ \__/ /_/   
# /___/                                               
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 or later.
# See <https://www.gnu.org/licenses/>

set \
    -o errexit \
    -o nounset

# 当前脚本版本号
readonly version='v0.0.5 (2025.01.23)'

yellow='\033[1;33m'
red='\033[1;31m'
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
os_info=$(grep "^PRETTY_NAME=" /etc/*release | cut -d '"' -f 2 | sed 's/ (.*)//')
os_name=$(grep "^ID=" /etc/*release | awk -F'=' '{print $2}' | sed 's/"//g')
readonly os_info os_name

getdocker_pid='/tmp/getdocker.pid'
systemctl_cmd=$(which systemctl 2>/dev/null)
readonly getdocker_pid systemctl_cmd

trap "cleanup_exit ; exit 0" SIGINT SIGQUIT SIGTERM EXIT

cleanup_exit() {
    [ -f "$getdocker_pid" ] && sudo rm -f "$getdocker_pid"
}

if [ -f "$getdocker_pid" ] && kill -0 "$(cat "$getdocker_pid")" 2>/dev/null; then
    exit 1
fi

echo $$ > "$getdocker_pid"

# https://www.lddgo.net/string/text-to-ascii-art
print_logo() {
    echo -e "${yellow}            __     __        __
  ___ ____ / /____/ ___ ____/ /_____ ____ 
 / _ \`/ -_/ __/ _  / _ / __/  '_/ -_/ __/ 
 \_, /\__/\__/\_,_/\___\__/_/\_\\__/_/
/___/
"
    local os_text="操作系统: ${os_info}"
    _green "${os_text}"
    _cyan "当前脚本版本: ${version} 💀 \n"
}

# 安全清屏
clear_screen() {
    if [ -t 1 ]; then
        tput clear 2>/dev/null || echo -e "\033[2J\033[H" || clear
    fi
}

remove() {
    if [ $# -eq 0 ]; then
        _err_msg "$(_red '未提供软件包参数')"
        return 1
    fi

    check_installed() {
        local package="$1"
        if command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
            sudo rpm -q "$package" >/dev/null 2>&1
        elif command -v apt >/dev/null 2>&1; then
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
            if command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
                sudo dnf remove -y "$package"* || sudo yum remove -y "$package"*
            elif command -v apt >/dev/null 2>&1; then
                sudo apt purge -y "$package"*
            elif command -v apk >/dev/null 2>&1; then
                sudo apk del -y "$package"*
            fi
        else
            _err_msg "$(_red "${package}没有安装，跳过卸载！")"
        fi
    done
    return 0
}

geo_check() {
    local cloudflare_api ipinfo_api ipsb_api

    cloudflare_api=$(curl -sL -m 10 -A "Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0" "https://dash.cloudflare.com/cdn-cgi/trace" | sed -n 's/.*loc=\([^ ]*\).*/\1/p')
    ipinfo_api=$(curl -sL --connect-timeout 5 https://ipinfo.io/country)
    ipsb_api=$(curl -sL --connect-timeout 5 -A Mozilla https://api.ip.sb/geoip | sed -n 's/.*"country_code":"\([^"]*\)".*/\1/p')

    for api in "$cloudflare_api" "$ipinfo_api" "$ipsb_api"; do
        if [ -n "$api" ]; then
            country="$api"
            break
        fi
    done

    readonly country

    if [ -z "$country" ]; then
        _err_msg "$(_red '无法获取服务器所在地区，请检查网络后重试！')"
        end_message
        exit 1
    fi
}

statistics_runtime() {
    local runcount
    runcount=$(curl -fskL -m 2 --retry 2 -o - "https://hit.forvps.gq/https://github.com/honeok/cross/raw/master/get-docker.sh" | grep -m1 -oE "[0-9]+[ ]+/[ ]+[0-9]+") &&
    today_runcount=$(awk -F ' ' '{print $1}' <<< "$runcount") && total_runcount=$(awk -F ' ' '{print $3}' <<< "$runcount")
}

sudo() {
    if [ "$(id -ru)" -ne 0 ]; then
        if command -v sudo >/dev/null 2>&1; then
            sudo "$@"
        else
            _err_msg "$(_red '您的系统未安装sudo，因此无法进行该项操作')"
            end_message
            exit 1
        fi
    else
        "$@"
    fi
}

enable() {
    local _cmd
    local service_name="$1"
    if command -v apk >/dev/null 2>&1; then
        _cmd="sudo rc-update add $service_name default"
    else
        _cmd="sudo ${systemctl_cmd} enable $service_name"
    fi

    if $_cmd; then
        _suc_msg "$(_green "${service_name}已设置为开机自启")"
    else
        _err_msg "$(_red "${service_name}设置开机自启失败")"
    fi
}

disable() {
    local service_name="$1"
    if command -v apk >/dev/null 2>&1; then
        sudo rc-update del "$service_name"
    else
        sudo "${systemctl_cmd}" disable "$service_name"
    fi
}

start() {
    local _cmd
    local service_name="$1"
    
    if command -v apk >/dev/null 2>&1; then
        _cmd="sudo service $service_name start"
    else
        _cmd="sudo ${systemctl_cmd} start $service_name"
    fi

    if $_cmd; then
        _suc_msg "$(_green "${service_name}已启动")"
    else
        _err_msg "$(_red "${service_name}启动失败")"
    fi
}

stop() {
    local _cmd
    local service_name="$1"
    
    if command -v apk >/dev/null 2>&1; then
        _cmd="sudo service $service_name stop"
    else
        _cmd="sudo ${systemctl_cmd} stop $service_name"
    fi

    if $_cmd; then
        _suc_msg "$(_green "${service_name}已停止")"
    else
        _err_msg "$(_red "${service_name}停止失败")"
    fi
}

systemctl() {
    local _cmd="$1"
    local service_name="$2"

    if command -v apk >/dev/null 2>&1; then
        sudo service "$service_name" "$_cmd"
    else
        sudo "${systemctl_cmd}" "$_cmd" "$service_name"
    fi
}

fix_dpkg() {
    pkill -f -15 'apt|dpkg' || pkill -f -9 'apt|dpkg'
    for lockfile in "/var/lib/dpkg/lock" "/var/lib/dpkg/lock-frontend"; do
        [ -f "$lockfile" ] && sudo rm -f "$lockfile" >/dev/null 2>&1
    done
    sudo dpkg --configure -a
}

clean_repo_files() {
    [ -f "/etc/yum.repos.d/docker-ce.repo" ] && sudo rm -f /etc/yum.repos.d/docker-ce.repo >/dev/null 2>&1
    [ -f "/etc/yum.repos.d/docker-ce-staging.repo" ] && sudo rm -f /etc/yum.repos.d/docker-ce-staging.repo >/dev/null 2>&1
    [ -f "/etc/apt/keyrings/docker.asc" ] && sudo rm -f /etc/apt/keyrings/docker.asc >/dev/null 2>&1
    [ -f "/etc/apt/sources.list.d/docker.list" ] && sudo rm -f /etc/apt/sources.list.d/docker.list >/dev/null 2>&1
}

check_docker() {
    if command -v docker >/dev/null 2>&1 || \
        sudo docker --version >/dev/null 2>&1 || \
        sudo docker compose version >/dev/null 2>&1 || \
        command -v docker-compose >/dev/null 2>&1; then
        _err_msg "$(_red 'Docker已安装，正在退出安装程序！')"
        end_message
        exit 0
    else
        install_docker
    fi
}

install_docker() {
    local pkg_cmd version_code repo_url gpgkey_url

    geo_check

    echo
    _info_msg "$(_yellow '正在安装docker环境！')"
    if [[ "$os_name" == "rocky" || "$os_name" == "almalinux" || "$os_name" == "centos" ]]; then
        remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine >/dev/null 2>&1

        if command -v dnf >/dev/null 2>&1; then
            if ! sudo dnf config-manager --help >/dev/null 2>&1; then
                sudo dnf install -y dnf-plugins-core
            fi
            pkg_cmd='dnf'
        elif command -v yum >/dev/null 2>&1; then
            if ! sudo rpm -q yum-utils >/dev/null 2>&1; then
                sudo yum install -y yum-utils
            fi
            pkg_cmd='yum'
        else
            _err_msg "$(_red '未知的包管理器！')"
            end_message
            exit 1
        fi

        clean_repo_files

        if [[ "$country" == "CN" ]]; then
            repo_url="https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo"
        else
            repo_url="https://download.docker.com/linux/centos/docker-ce.repo"
        fi

        if [[ "$pkg_cmd" == "dnf" ]]; then
            sudo dnf config-manager --add-repo "$repo_url" >/dev/null 2>&1
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        elif [[ "$pkg_cmd" == "yum" ]]; then
            sudo yum-config-manager --add-repo "$repo_url" >/dev/null 2>&1
            sudo yum makecache fast
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        fi

        enable docker
        start docker
    elif [[ "$os_name" == "rhel" ]]; then
        remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine podman runc >/dev/null 2>&1

        if ! dnf config-manager --help >/dev/null 2>&1; then
            dnf install -y dnf-plugins-core
        fi

        clean_repo_files

        if [[ "$country" == "CN" ]]; then
            sudo dnf config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/rhel/docker-ce.repo
        else
            sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
        fi

        sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        enable docker
        start docker
    elif [[ "$os_name" == "debian" || "$os_name" == "ubuntu" ]]; then
        # version_code="$(. /etc/*release && echo "$VERSION_CODENAME")"
        version_code="$(grep "^VERSION_CODENAME" /etc/*release | cut -d= -f2)"

        remove docker.io docker-doc docker-compose podman-docker containerd runc >/dev/null 2>&1

        clean_repo_files

        if [[ "$country" == "CN" ]]; then
            repo_url="https://mirrors.aliyun.com/docker-ce/linux/${os_name}"
            gpgkey_url="https://mirrors.aliyun.com/docker-ce/linux/${os_name}/gpg"
        else
            repo_url="https://download.docker.com/linux/${os_name}"
            gpgkey_url="https://download.docker.com/linux/${os_name}/gpg"
        fi

        fix_dpkg
        sudo apt-get -qq update
        # sudo apt-get install -y -qq ca-certificates curl apt-transport-https lsb-release gnupg
        sudo apt-get install -y -qq ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL "$gpgkey_url" -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        # add the repository to apt sources
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] $repo_url $version_code stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        sudo apt-get -qq update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        enable docker
        start docker
    elif [[ "$os_name" == "alpine" ]]; then

        if [[ "$country" == "CN" ]]; then
            #s#old#new#g
            sed -i "s#dl-cdn.alpinelinux.org#mirrors.aliyun.com#g" /etc/apk/repositories
        fi

        sudo apk update
        sudo apk add docker docker-compose
        enable docker
        start docker
    else
        _err_msg "$(_red '当前操作系统不被支持！')"
        end_message
        exit 0
    fi
    echo
}

uninstall_docker() {
    local docker_datadir=("/var/lib/docker" "/var/lib/containerd" "/etc/docker" "/opt/containerd")
    local docker_depend_files=("/etc/yum.repos.d/docker*" "/etc/apt/sources.list.d/docker.*" "/etc/apt/keyrings/docker.*" "/var/log/docker.*")
    local bin_files=("/usr/bin/docker" "/usr/bin/docker-compose")

    echo
    # 停止并删除Docker服务和容器
    stop_and_remove_docker() {
        local running_containers
        running_containers=$(sudo docker ps -a -q)
        [ -n "$running_containers" ] && sudo docker rm -f "$running_containers" >/dev/null 2>&1
        stop docker.socket >/dev/null 2>&1
        stop docker
        disable docker
    }

    # 移除Docker文件和仓库文件
    cleanup_files() {
        for pattern in "${docker_depend_files[@]}"; do
            for file in $pattern; do
                [ -e "$file" ] && sudo rm -f "$file" >/dev/null 2>&1
            done
        done

        for file in "${docker_datadir[@]}" "${bin_files[@]}"; do
            [ -e "$file" ] && sudo rm -rf "$file" >/dev/null 2>&1
        done
    }

    # 检查Docker是否安装
    if ! command -v docker >/dev/null 2>&1; then
        _err_msg "$(_red 'Docker未安装在系统上，无法继续卸载')"
        return 1
    fi

    stop_and_remove_docker
    remove docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    cleanup_files

    hash -r
    sleep 2

    if command -v docker >/dev/null 2>&1 || [ -e "/usr/bin/docker" ]; then
        _err_msg "$(_red 'Docker卸载失败，请手动检查')"
        return 1
    else
        _suc_msg "$(_green 'Docker和Docker Compose已卸载，并清理文件夹和相关依赖')"
    fi
    echo
}

docker_version() {
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

    echo "Docker版本: v${docker_v}"
    echo "Docker Compose版本: v${docker_compose_v}"
    echo
    _yellow "正在获取Docker信息"
    sleep 2s
    sudo docker version

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

docker_status() {
    if sudo "${systemctl_cmd}" is-active --quiet docker || \
        sudo docker info >/dev/null 2>&1 || \
        sudo /etc/init.d/docker status | grep -q 'started' || \
        sudo service docker status >/dev/null 2>&1 || \
        curl -s --unix-socket /var/run/docker.sock http://localhost/version >/dev/null 2>&1; then
        _suc_msg "$(_green 'Docker已完成自检，启动并设置开机自启！')"
    else
        _err_msg "$(_red 'Docker状态检查失败或服务无法启动，请检查安装日志或手动启动Docker服务')"
        end_message
        exit 1
    fi
}

end_message() {
    local current_time current_timezone message_time

    statistics_runtime

    current_time=$(date '+%Y-%m-%d %H:%M:%S')
    current_timezone=$(date +"%Z %z")

    # https://github.com/koalaman/shellcheck/issues/3093
    message_time="服务器当前时间: ${current_time} 时区: ${current_timezone} 脚本执行完成"
    printf "\033[1;32m%s\033[0m\n" "$message_time"
    _purple "感谢使用本脚本！如有疑问，请访问 https://www.honeok.com 获取更多信息"
    _yellow "脚本当天运行次数: ${today_runcount} 累计运行次数: ${total_runcount}"
}

standalone_logic() {
    clear_screen

    # 操作系统和权限校验
    if [[ "$os_name" != "debian" && "$os_name" != "ubuntu" && "$os_name" != "centos" && "$os_name" != "rhel" && "$os_name" != "rocky" && "$os_name" != "almalinux" && "$os_name" != "alpine" ]]; then
        _err_msg "$(_red '当前操作系统不被支持！')"
        end_message
        exit 1
    fi

    print_logo
    check_docker
    docker_version
    docker_status
    end_message
}

if [ "$#" -eq 0 ]; then
    standalone_logic
    exit 0
else
    while [[ "$#" -ge 1 ]]; do
        case "$1" in
            -y | --install)
                shift
                standalone_logic
                ;;
            -d | --remove)
                print_logo
                uninstall_docker
                end_message
                exit 0
                ;;
            *)
                _err_msg "$(_red "无效选项, 当前参数 '$1' 不被支持！")"
                end_message
                exit 1
                ;;
        esac
    done
fi