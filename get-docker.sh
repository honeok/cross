#!/usr/bin/env bash
#
# Description: Script for quickly installing the latest Docker-CE on supported Linux distros.
#
# Copyright (C) 2023 - 2025 honeok <honeok@duck.com>
#
# https://github.com/honeok/cross/raw/master/get-docker.sh

# 当前脚本版本号
version='v0.0.2 (2025.01.01)'

yellow='\033[93m'
red='\033[31m'
green='\033[92m'
blue='\033[94m'
cyan='\033[96m'
purple='\033[95m'
gray='\033[37m'
orange='\033[38;5;214m'
white='\033[0m'
_yellow() { echo -e "${yellow}$*${white}"; }
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }
_blue() { echo -e "${blue}$*${white}"; }
_cyan() { echo -e "${cyan}$*${white}"; }
_purple() { echo -e "${purple}$*${white}"; }
_gray() { echo -e "${gray}$*${white}"; }
_orange() { echo -e "${orange}$*${white}"; }
_white() { echo -e "${white}$*${white}"; }

_err_msg() { echo -e "\033[41m\033[1m警告${white} $*"; }

export DEBIAN_FRONTEND=noninteractive

github_proxy='https://cdn.611611.best/'
getdocker_pid='/tmp/getdocker.pid'

# 操作系统和权限校验
[ "$(id -ru)" -ne "0" ] && _err_msg "$(_red '需要root用户才能运行！')" && exit 1
os_info=$(grep '^PRETTY_NAME=' /etc/*release | cut -d '"' -f 2 | sed 's/ (.*)//')
os_name=$(grep ^ID= /etc/*release | awk -F'=' '{print $2}' | sed 's/"//g')
[[ "$os_name" != "debian" && "$os_name" != "ubuntu" && "$os_name" != "centos" && "$os_name" != "rhel" && "$os_name" != "rocky" && "$os_name" != "almalinux" "$os_name" != "alpine" ]] && { _err_msg "$(_red '当前操作系统不被支持！')" && exit 0 ;}

trap "cleanup_exit ; echo "" ; exit 0" SIGINT SIGQUIT SIGTERM EXIT

cleanup_exit() {
    [ -f "$getdocker_pid" ] && rm -f "$getdocker_pid"
}

if [ -f "$getdocker_pid" ] && kill -0 "$(cat "$getdocker_pid")" 2>/dev/null; then
    exit 1
fi

echo $$ > "$getdocker_pid"

if [ "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" != "/root" ]; then
    cd /root >/dev/null 2>&1
fi

# https://www.lddgo.net/string/text-to-ascii-art
print_logo() {
cat << 'EOF'
              __      __             __             
  ___ _ ___  / /_ ___/ / ___  ____  / /__ ___   ____
 / _ `// -_)/ __// _  / / _ \/ __/ /  '_// -_) / __/
 \_, / \__/ \__/ \_,_/  \___/\__/ /_/\_\ \__/ /_/   
/___/                                               
EOF
    local os_text="当前操作系统: ${os_info}"
    _green "${os_text}"
}

remove() {
    if [ $# -eq 0 ]; then
        _red "未提供软件包参数"
        return 1
    fi

    check_installed() {
        local package="$1"
        if command -v dnf >/dev/null 2>&1; then
            rpm -q "$package" >/dev/null 2>&1
        elif command -v yum >/dev/null 2>&1; then
            rpm -q "$package" >/dev/null 2>&1
        elif command -v apt >/dev/null 2>&1; then
            dpkg -l | grep -qw "$package"
        elif command -v apk >/dev/null 2>&1; then
            apk info | grep -qw "$package"
        else
            _red "未知的包管理器"
            return 1
        fi
        return 0
    }

    for package in "$@"; do
        _yellow "正在卸载$package"
        if check_installed "$package"; then
            if command -v dnf >/dev/null 2>&1; then
                dnf remove "$package"* -y
            elif command -v yum >/dev/null 2>&1; then
                yum remove "$package"* -y
            elif command -v apt >/dev/null 2>&1; then
                apt purge "$package"* -y
            elif command -v apk >/dev/null 2>&1; then
                apk del "$package"* -y
            fi
        else
            _red "${package}没有安装，跳过卸载！"
        fi
    done
    return 0
}

systemctl() {
    local cmd="$1"
    local service_name="$2"

    if command -v apk >/dev/null 2>&1; then
        service "$service_name" "$cmd"
    else
        /usr/bin/systemctl "$cmd" "$service_name"
    fi
}

# 脚本当天及累计运行次数统计
statistics_runtime() {
    local runcount
	runcount=$(wget --no-check-certificate -qO- --tries=2 --timeout=2 "https://hit.forvps.gq/https://raw.githubusercontent.com/honeok/cross/master/get-docker.sh" 2>&1 | grep -m1 -oE "[0-9]+[ ]+/[ ]+[0-9]+") &&
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
    if command -v docker >/dev/null 2>&1 || docker --version >/dev/null 2>&1 || \
        docker compose version >/dev/null 2>&1 || command -v docker-compose >/dev/null 2>&1; then
            _err_msg "$(_red 'Docker已安装，正在退出安装程序！')"
            end_message
            exit 0
	else
		install_docker
    fi
}

install_docker() {
    if [[ "$os_name" == 'rhel' && "$os_name" == 'rocky' && "$os_name" == 'almalinux' ]]; then
        if ! dnf config-manager --help >/dev/null 2>&1; then
            dnf install -y dnf-plugins-core
        fi

        [ -f /etc/yum.repos.d/docker*.repo ] && rm -f /etc/yum.repos.d/docker*.repo >/dev/null 2>&1

        # 判断地区安装
        if [[ "$country" == 'CN' ]];then
            dnf config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo >/dev/null 2>&1
        else
            dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo >/dev/null 2>&1
        fi

        dnf install -y docker-ce docker-ce-cli containerd.io
        systemctl enable docker --now
    elif [[ "$os_name" == 'centos' && "$(grep ^VERSION_ID= /etc/*release | awk -F'=' '{print $2}' | sed 's/"//g')" == '7' ]]; then
        remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine

        if ! rpm -q yum-utils >/dev/null 2>&1; then
            yum install -y yum-utils
        fi

        [ -f /etc/yum.repos.d/docker*.repo ] && rm -f /etc/yum.repos.d/docker*.repo >/dev/null 2>&1

        # 根据地区选择镜像源
        if [ "$country" == 'CN' ]; then
            yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
        else
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        fi
        yum makecache fast
        yum install docker-ce docker-ce-cli containerd.io -y
        systemctl enable docker --now
    elif [[ "$os_name" == 'debian' && "$os_name" == 'ubuntu']]; then
        codename="$(grep ^VERSION_CODENAME /etc/*release | cut -d= -f2)"

        remove docker.io docker-doc docker-compose podman-docker containerd runc

        # 根据地区选择镜像源
        if [ "$country" == 'CN' ]; then
            repo_url="https://mirrors.aliyun.com/docker-ce/linux/${os_name}"
            gpgkey_url="https://mirrors.aliyun.com/docker-ce/linux/${os_name}/gpg"
        else
            repo_url="https://download.docker.com/linux/${os_name}"
            gpgkey_url="https://download.docker.com/linux/${os_name}/gpg"
        fi

        sudo apt update
        sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL "$gpgkey_url" -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] $repo_url $codename stable" | sudo tee /etc/apt/sources.list.d/docker.list
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io
        systemctl enable docker --now
    elif [[ "$os_name" == 'alpine' ]]; then
        apk add docker docker-compose
        rc-update add docker default
        service docker start
    else
        _err_msg "$(_red '当前操作系统不被支持！')"
        end_message
        exit 0
    fi
}

uninstall_docker() {
    local docker_data_files=("/var/lib/docker" "/var/lib/containerd" "/etc/docker" "/opt/containerd" "/data/docker_data")
    local docker_depend_files=("/etc/yum.repos.d/docker*" "/etc/apt/sources.list.d/docker.*" "/etc/apt/keyrings/docker.*" "/var/log/docker.*")
    local binary_files=("/usr/bin/docker" "/usr/bin/docker-compose")  # 删除二进制文件路径

    # 停止并删除Docker服务和容器
    stop_and_remove_docker() {
        local running_containers=$(docker ps -aq)
        [ -n "$running_containers" ] && docker rm -f "$running_containers" >/dev/null 2>&1
        stop docker >/dev/null 2>&1
        disable docker >/dev/null 2>&1
    }

    # 移除Docker文件和仓库文件
    cleanup_files() {
        for pattern in "${docker_depend_files[@]}"; do
            for file in $pattern; do
                [ -e "$file" ] && rm -rf "$file" >/dev/null 2>&1
            done
        done

        for file in "${docker_data_files[@]}" "${binary_files[@]}"; do
            [ -e "$file" ] && rm -rf "$file" >/dev/null 2>&1
        done
    }

    # 检查Docker是否安装
    if ! command -v docker >/dev/null 2>&1; then
        _red "Docker未安装在系统上，无法继续卸载"
        return 1
    fi

    stop_and_remove_docker

    remove docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
    cleanup_files

    # 清除命令缓存
    hash -r

    sleep 2

    # 检查卸载是否成功
    if command -v docker >/dev/null 2>&1 || [ -e "/usr/bin/docker" ]; then
        _red "Docker卸载失败，请手动检查"
        return 1
    else
        _green "Docker和Docker Compose已卸载，并清理文件夹和相关依赖"
    fi
}

# 显示已安装Docker和Docker Compose版本
docker_version() {
    local docker_v=""
    local docker_compose_v=""

    # 获取Docker版本
    if command -v docker >/dev/null 2>&1; then
        docker_v=$(docker --version | awk -F '[ ,]' '{print $3}')
    elif command -v docker.io >/dev/null 2>&1; then
        docker_v=$(docker.io --version | awk -F '[ ,]' '{print $3}')
    fi

    # 获取Docker Compose版本
    if docker compose version >/dev/null 2>&1; then
        docker_compose_v=$(docker compose version --short)
    elif command -v docker-compose >/dev/null 2>&1; then
        docker_compose_v=$(docker-compose version --short)
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

main() {
	print_logo

	# 执行卸载 Docker
	if [ "$1" == "uninstall" ]; then
		uninstall_docker
		end_message
		exit 0
	fi

    check_docker

	# 完成脚本
	end_message
}

main "$@"
exit 0