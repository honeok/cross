#!/usr/bin/env bash
#
# Description: Script for quickly installing the latest Docker-CE on supported Linux distros.
# System Required:  Debian11+ Ubuntu18+ Centos7+ rhel9+ Rocky8+ Almalinux8+ Alpine19+
#
# Copyright (C) 2023 - 2025 honeok <honeok@duck.com>
#
# https://github.com/honeok/cross/raw/master/get-docker.sh

# 当前脚本版本号
version='v0.0.2 (2025.01.02)'

yellow='\033[93m'
red='\033[31m'
green='\033[92m'
purple='\033[95m'
white='\033[0m'
_yellow() { echo -e "${yellow}$*${white}"; }
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }
_purple() { echo -e "${purple}$*${white}"; }

_err_msg() { echo -e "\033[41m\033[1m警告${white} $*"; }
_suc_msg() { echo -e "\033[42m\033[1m成功${white} $*"; }

export DEBIAN_FRONTEND=noninteractive

getdocker_pid='/tmp/getdocker.pid'

# 操作系统和权限校验
os_info=$(grep '^PRETTY_NAME=' /etc/*release | cut -d '"' -f 2 | sed 's/ (.*)//')
os_name=$(grep ^ID= /etc/*release | awk -F'=' '{print $2}' | sed 's/"//g')
[[ "$os_name" != "debian" && "$os_name" != "ubuntu" && "$os_name" != "centos" && "$os_name" != "rhel" && "$os_name" != "rocky" && "$os_name" != "almalinux" && "$os_name" != "alpine" ]] && { _err_msg "$(_red '当前操作系统不被支持！')" && exit 0; }

trap "cleanup_exit ; echo "" ; exit 0" SIGINT SIGQUIT SIGTERM EXIT

cleanup_exit() {
    [ -f "$getdocker_pid" ] && sudo rm -f "$getdocker_pid"
}

if [ -f "$getdocker_pid" ] && kill -0 "$(cat "$getdocker_pid")" 2>/dev/null; then
    exit 1
fi

echo $$ > "$getdocker_pid"

if [ "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" != "/root" ]; then
    sudo cd /root >/dev/null 2>&1
fi

# https://www.lddgo.net/string/text-to-ascii-art
print_logo() {
echo -e "${yellow}            __     __        __
  ___ ____ / /____/ ___ ____/ /_____ ____ 
 / _ \`/ -_/ __/ _  / _ / __/  '_/ -_/ __/ 
 \_, /\__/\__/\_,_/\___\__/_/\_\\__/_/
/___/
"
    local os_text="当前操作系统: ${os_info}"
    _green "${os_text}"
    _purple "当前脚本版本: ${version}"
}

remove() {
    if [ $# -eq 0 ]; then
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
        elif command -v apk >/dev/null 2>&1; then
            sudo apk info | grep -qw "$package"
        else
            _err_msg "$(_red "未知的包管理器")"
            return 1
        fi
        return 0
    }

    for package in "$@"; do
        _yellow "正在卸载$package"
        if check_installed "$package"; then
            if command -v dnf >/dev/null 2>&1; then
                sudo dnf remove "$package"* -y
            elif command -v yum >/dev/null 2>&1; then
                sudo yum remove "$package"* -y
            elif command -v apt >/dev/null 2>&1; then
                sudo apt purge "$package"* -y
            elif command -v apk >/dev/null 2>&1; then
                sudo apk del "$package"* -y
            fi
        else
            _err_msg "$(_red "${package}没有安装，跳过卸载！")"
        fi
    done
    return 0
}

sudo() {
    if [ "$(id -ru)" -ne 0 ]; then
        if command -v sudo >/dev/null 2>&1; then
            sudo "$@"
        else
            _err_msg "$(_red '您的系统未安装sudo，因此无法进行该项操作')"
            exit 1
        fi
    else
        "$@"
    fi
}

enable() {
    local service_name="$1"
    if command -v apk >/dev/null 2>&1; then
        sudo rc-update add "$service_name" default
    else
        sudo /usr/bin/systemctl enable "$service_name"
    fi
    [ $? -eq 0 ] && _suc_msg "$(_green "${service_name}已设置为开机自启")" || _err_msg "$(_red "${service_name}设置开机自启失败")"
}

disable() {
    local service_name="$1"
    if command -v apk >/dev/null 2>&1; then
        sudo rc-update del "$service_name"
    else
        sudo /usr/bin/systemctl disable "$service_name"
    fi
}

start() {
    local service_name="$1"
    if command -v apk >/dev/null 2>&1; then
        sudo service "$service_name" start
    else
        sudo /usr/bin/systemctl start "$service_name"
    fi
    [ $? -eq 0 ] && _suc_msg "$(_green "${service_name}已启动")" || _err_msg "$(_red "${service_name}启动失败")"
}

stop() {
    local service_name="$1"
    if command -v apk >/dev/null 2>&1; then
        sudo service "$service_name" stop
    else
        sudo /usr/bin/systemctl stop "$service_name"
    fi
    [ $? -eq 0 ] && _suc_msg "$(_green "${service_name}已停止")" || _err_msg "$(_red "${service_name}停止失败")"
}

systemctl() {
    local cmd="$1"
    local service_name="$2"

    if command -v apk >/dev/null 2>&1; then
        sudo service "$service_name" "$cmd"
    else
        sudo /usr/bin/systemctl "$cmd" "$service_name"
    fi
}

statistics_runtime() {
    local runcount
    runcount=$(curl -fskL --max-time 2 --retry 2 "https://hit.forvps.gq/https://raw.githubusercontent.com/honeok/cross/master/get-docker.sh" -o - | grep -m1 -oE "[0-9]+[ ]+/[ ]+[0-9]+") &&
    today_runcount=$(awk -F ' ' '{print $1}' <<< "$runcount") &&
    total_runcount=$(awk -F ' ' '{print $3}' <<< "$runcount")
}

geo_check() {
    local cloudflare_api="https://dash.cloudflare.com/cdn-cgi/trace"
    local user_agent="Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0"

    country=$(curl -A "$user_agent" -m 10 -s "$cloudflare_api" | sed -n 's/.*loc=\([^ ]*\).*/\1/p')
    [ -z "$country" ] && _err_msg "$(_red '无法获取服务器所在地区，请检查网络！')" && exit 1
}

end_message() {
    local current_time current_timezone

    statistics_runtime

    current_time=$(date '+%Y-%m-%d %H:%M:%S')
    current_timezone=$(date +"%Z %z")

    printf "${green}服务器当前时间: ${current_time} 时区: ${current_timezone} 脚本执行完成${white}\n"
    _purple "感谢使用本脚本！如有疑问，请访问honeok.com获取更多信息"
    _yellow "脚本当天运行次数: ${today_runcount} 累计运行次数: ${total_runcount}"
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
    local pkg_cmd version_codename repo_url gpgkey_url

    geo_check

    if [[ "$os_name" == "rocky" && "$os_name" == "almalinux" && "$os_name" == "centos" ]]; then
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

        [ -f /etc/yum.repos.d/docker*.repo ] && sudo rm -f /etc/yum.repos.d/docker*.repo >/dev/null 2>&1

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
        if ! dnf config-manager --help >/dev/null 2>&1; then
            dnf install -y dnf-plugins-core
        fi

        [ -f /etc/yum.repos.d/docker*.repo ] && sudo rm -f /etc/yum.repos.d/docker*.repo >/dev/null 2>&1

        if [[ "$country" == "CN" ]];then
            sudo dnf config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/rhel/docker-ce.repo >/dev/null 2>&1
        else
            sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo >/dev/null 2>&1
        fi

        sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        enable docker
        start docker
    elif [[ "$os_name" == "debian" && "$os_name" == "ubuntu" ]]; then
        # os_name="$(lsb_release -si)"
        # version_codename="$(lsb_release -cs)"
        # version_codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"
        version_codename="$(grep ^VERSION_CODENAME /etc/*release | cut -d= -f2)"

        remove docker.io docker-doc docker-compose podman-docker containerd runc

        [ -f /etc/apt/keyrings/docker.asc ] && sudo rm -f /etc/apt/keyrings/docker.asc >/dev/null 2>&1
        [ -f /etc/apt/sources.list.d/docker.list ] && sudo rm -f /etc/apt/sources.list.d/docker.list >/dev/null 2>&1

        if [ "$country" == "CN" ]; then
            repo_url="https://mirrors.aliyun.com/docker-ce/linux/${os_name}"
            gpgkey_url="https://mirrors.aliyun.com/docker-ce/linux/${os_name}/gpg"
        else
            repo_url="https://download.docker.com/linux/${os_name}"
            gpgkey_url="https://download.docker.com/linux/${os_name}/gpg"
        fi

        sudo apt-get -qq update
        # sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
        sudo apt-get install -y -qq ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL "$gpgkey_url" -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        # add the repository to apt sources
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] $repo_url $version_codename stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        sudo apt-get -qq update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        enable docker
        start docker
    elif [[ "$os_name" == "alpine" ]]; then
        if [ "$country" == "CN" ]; then
            repo_url="https://mirrors.aliyun.com/alpine/latest-stable/community"
        else
            repo_url="http://dl-cdn.alpinelinux.org/alpine/latest-stable/community"

        if ! grep -q "$repo_url" /etc/apk/repositories; then
            echo "$repo_url" >> /etc/apk/repositories
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
}

uninstall_docker() {
    local docker_datadir=("/var/lib/docker" "/var/lib/containerd" "/etc/docker" "/opt/containerd")
    local docker_depend_files=("/etc/yum.repos.d/docker*" "/etc/apt/sources.list.d/docker.*" "/etc/apt/keyrings/docker.*" "/var/log/docker.*")
    local bin_files=("/usr/bin/docker" "/usr/bin/docker-compose")

    # 停止并删除Docker服务和容器
    stop_and_remove_docker() {
        local running_containers
        running_containers=$(docker ps -aq)
        [ -n "$running_containers" ] && sudo docker rm -f "$running_containers" >/dev/null 2>&1
        stop docker
        disable docker
    }

    # 移除Docker文件和仓库文件
    cleanup_files() {
        for pattern in "${docker_depend_files[@]}"; do
            for file in "$pattern"; do
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
    if sudo systemctl is-active --quiet docker || \
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

if [ "$#" -eq 0 ]; then
    check_docker
    docker_version
    docker_status
    end_message
    exit 0
else
    for arg in "$@"; do
        case $arg in
            -d|d|-D|D)
                uninstall_docker
                end_message
                exit 0
                ;;
            *)
                _err_msg "$(_red "无效选项, 当前参数${arg}不被支持！")"
                ;;
        esac
    done
fi
