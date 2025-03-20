#!/usr/bin/env bash
#
# Description: Installs the latest Docker CE on supported Linux distributions.
# Supported Systems: debian10+ ubuntu20+ centos7+ rhel8+ rocky8+ alma8+ alpine3.20+
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
readonly version='v0.1.3 (2025.03.20)'

red='\033[91m'
green='\033[92m'
yellow='\033[93m'
purple='\033[95m'
cyan='\033[96m'
white='\033[0m'
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }
_yellow() { echo -e "${yellow}$*${white}"; }
_purple() { echo -e "${purple}$*${white}"; }
_cyan() { echo -e "${cyan}$*${white}"; }

_err_msg() { echo -e "\033[41m\033[1mWarn${white} $*"; }
_suc_msg() { echo -e "\033[42m\033[1mSuccess${white} $*"; }
_info_msg() { echo -e "\033[43m\033[1mTis${white} $*"; }

# 各变量默认值
getdocker_pid='/tmp/getdocker.pid'
os_info=$(grep "^PRETTY_NAME=" /etc/*-release | cut -d '"' -f 2 | sed 's/ (.*)//')
os_name=$(grep "^ID=" /etc/*-release | awk -F'=' '{print $2}' | sed 's/"//g')
script_url='https://github.com/honeok/cross/raw/master/get-docker.sh'
ua_browser='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36'
readonly getdocker_pid os_info os_name script_url ua_browser

if [ -f "$getdocker_pid" ] && kill -0 "$(cat "$getdocker_pid")" 2>/dev/null; then
    _err_msg "$(_red 'The script seems to be running, please do not run it again!')" && exit 1
fi

_exit() {
    local return_value="$?"

    [ -f "$getdocker_pid" ] && rm -f "$getdocker_pid" 2>/dev/null
    exit "$return_value"
}

trap '_exit' SIGINT SIGQUIT SIGTERM EXIT

echo $$ > "$getdocker_pid"

# Logo generation from: https://www.lddgo.net/string/text-to-ascii-art (Small Slant)
_show_logo() {
    echo -e "${yellow}  _____    __     __        __ 
 / ______ / /____/ ___ ____/ /_____ ____
/ (_ / -_/ __/ _  / _ / __/  '_/ -_/ __/
\___/\__/\__/\_,_/\___\__/_/\_\\__/_/
"
    printf "\n"
    _green " System   : $os_info"
    echo "$(_green " Version  : $version") $(_purple '\xF0\x9F\x90\xB3')"
}

_exists() {
    local _cmd="$1"
    if type "$_cmd" >/dev/null 2>&1; then
        return 0
    elif command -v "$_cmd" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

runtime_count() {
    local runcount
    runcount=$(curl -fskL -m 3 --retry 1 "https://hit.forvps.gq/$script_url" | grep -m1 -oE "[0-9]+[ ]+/[ ]+[0-9]+")
    today_runcount=$(awk -F ' ' '{print $1}' <<< "$runcount")
    total_runcount=$(awk -F ' ' '{print $3}' <<< "$runcount")
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

end_message() {
    local current_time
    current_time=$(date '+%Y-%m-%d %H:%M:%S %Z')
    runtime_count
    _green "Current server time: $current_time Script execution completed."
    _purple 'Thank you for using this script! If you have any questions, please visit https://www.honeok.com get more information.'
    _yellow "Number of script runs today: $today_runcount Total number of script runs: $total_runcount"
}

os_permission() {
    case "$os_name" in
        'debian')
            # 检查Debian版本是否小于10
            if [ "$(grep -oE '[0-9]+' /etc/debian_version | head -1)" -lt 10 ]; then
                _err_msg "$(_red 'This version of Debian is no longer supported!')" && end_message && exit 1
            fi
        ;;
        'ubuntu')
            # 检查Ubuntu版本是否小于20.04
            if [ "$(grep "^VERSION_ID" /etc/*-release | cut -d '"' -f 2 | tr -d '.')" -lt '2004' ]; then
                _err_msg "$(_red 'This version of Ubuntu is no longer supported!')" && end_message && exit 1
            fi
        ;;
        'rhel' | 'centos' | 'rocky' | 'almalinux')
            # 检查RHEL/CentOS/Rocky/AlmaLinux版本是否小于7
            if [ "$(grep -shoE '[0-9]+' /etc/redhat-release /etc/centos-release /etc/rocky-release /etc/almalinux-release | head -1)" -lt 7 ]; then
                _err_msg "$(_red "This installer requires version $os_name 9 or higher.")" && end_message && exit 1
            fi
        ;;
        'alpine')
            # 检查Alpine版本是否小于3.20
            if [ "$(awk -F'.' '{print $1$2}' /etc/alpine-release)" -lt 320 ]; then
                _err_msg "$(_red "This installer requires Alpine 3.20 or higher.")" && end_message && exit 1
            fi
        ;;
        *) _err_msg "$(_red 'The current operating system is not supported!')" && end_message && exit 1 ;;
    esac
}

# 虚拟化校验
virt_check() {
    local processor_type kernel_logs system_manufacturer system_product_name system_version

    processor_type=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')

    if _exists "dmesg" >/dev/null 2>&1; then
        kernel_logs=$(dmesg 2>/dev/null)
    fi

    if _exists "dmidecode" >/dev/null 2>&1; then
        system_manufacturer=$(dmidecode -s system-manufacturer 2>/dev/null)
        system_product_name=$(dmidecode -s system-product-name 2>/dev/null)
        system_version=$(dmidecode -s system-version 2>/dev/null)
    fi

    if grep -qai docker /proc/1/cgroup; then
        virt_type="Docker"
    elif grep -qai lxc /proc/1/cgroup; then
        virt_type="LXC"
    elif grep -qai container=lxc /proc/1/environ; then
        virt_type="LXC"
    elif [ -f /proc/user_beancounters ]; then
        virt_type="OpenVZ"
    elif echo "$kernel_logs" | grep -qi "kvm-clock" 2>/dev/null; then
        virt_type="KVM"
    elif echo "$processor_type" | grep -qi "kvm" 2>/dev/null; then
        virt_type="KVM"
    elif echo "$processor_type" | grep -qi "qemu" 2>/dev/null; then
        virt_type="KVM"
    elif grep -qi "kvm" "/sys/devices/virtual/dmi/id/product_name" 2>/dev/null; then
        virt_type="KVM"
    elif grep -qi "qemu" "/proc/scsi/scsi" 2>/dev/null; then
        virt_type="KVM"
    elif echo "$kernel_logs" | grep -qi "vmware virtual platform" 2>/dev/null; then
        virt_type="VMware"
    elif echo "$kernel_logs" | grep -qi "parallels software international" 2>/dev/null; then
        virt_type="Parallels"
    elif echo "$kernel_logs" | grep -qi "virtualbox" 2>/dev/null; then
        virt_type="VirtualBox"
    elif [ -e /proc/xen ]; then
        if grep -qi "control_d" "/proc/xen/capabilities" 2>/dev/null; then
            virt_type="Xen-Dom0"
        else
            virt_type="Xen-DomU"
        fi
    elif [ -f "/sys/hypervisor/type" ] && grep -qi "xen" "/sys/hypervisor/type" 2>/dev/null; then
        virt_type="Xen"
    elif echo "$system_manufacturer" | grep -qi "microsoft corporation" 2>/dev/null; then
        if echo "$system_product_name" | grep -qi "virtual machine" 2>/dev/null; then
            if echo "$system_version" | grep -qi "7.0" 2>/dev/null || echo "$system_version" | grep -qi "hyper-v" 2>/dev/null; then
                virt_type="Hyper-V"
            else
                virt_type="Microsoft Virtual Machine"
            fi
        fi
    else
        virt_type="Dedicated"
    fi
}

virt_permission() {
    virt_check

    if [ "$virt_type" = 'Docker' ] || [ "$virt_type" = 'LXC' ] || [ "$virt_type" = "OpenVZ" ]; then
        _err_msg "$(_red 'The current virtualization architecture is not supported!')" && end_message && exit 1
    fi
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
        elif _exists apk; then
            apk del "$package"
        fi
    done
}

pre_check() {
    # 备用 www.qualcomm.cn
    cloudflare_api='www.garmin.com.cn'

    if [ "$(id -ru)" -ne "0" ] || [ "$EUID" -ne "0" ]; then
        _err_msg "$(_red 'This script must be run as root!')" && exit 1
    fi
    if [ "$(ps -p $$ -o comm=)" != "bash" ] || readlink /proc/$$/exe | grep -q "dash"; then
        _err_msg "$(_red 'This script needs to be run with bash, not sh!')" && exit 1
    fi
    _loc=$(curl -A "$ua_browser" -fskL -m 3 "https://$cloudflare_api/cdn-cgi/trace" | grep -i '^loc=' | cut -d'=' -f2 | xargs)
    if [ -z "$_loc" ]; then
        _err_msg "$(_red 'Cannot retrieve server location. Check your network and try again.')" && end_message && exit 1
    fi
}

systemctl() {
    local _cmd="$1"
    local service_name="$2"

    systemctl_cmd=$(which systemctl 2>/dev/null)

    if _exists apk >/dev/null 2>&1; then
        service "$service_name" "$_cmd"
    else
        "$systemctl_cmd" "$_cmd" "$service_name"
    fi
}

fix_dpkg() {
    pkill -f -15 'apt|dpkg' || pkill -f -9 'apt|dpkg'
    for lockfile in "/var/lib/dpkg/lock" "/var/lib/dpkg/lock-frontend"; do
        [ -f "$lockfile" ] &&  rm -f "$lockfile" >/dev/null 2>&1
    done
    dpkg --configure -a
}

clean_repo_files() {
    [ -f "/etc/yum.repos.d/docker-ce.repo" ] &&  rm -f /etc/yum.repos.d/docker-ce.repo 2>/dev/null
    [ -f "/etc/yum.repos.d/docker-ce-staging.repo" ] &&  rm -f /etc/yum.repos.d/docker-ce-staging.repo 2>/dev/null
    [ -f "/etc/apt/keyrings/docker.asc" ] &&  rm -f /etc/apt/keyrings/docker.asc 2>/dev/null
    [ -f "/etc/apt/sources.list.d/docker.list" ] &&  rm -f /etc/apt/sources.list.d/docker.list 2>/dev/null
}

_check_install() {
    if _exists 'docker' >/dev/null 2>&1 || \
        docker --version >/dev/null 2>&1 || \
        docker compose version >/dev/null 2>&1 || \
        _exists 'docker-compose' >/dev/null 2>&1; then
        _err_msg "$(_red 'Docker is already installed. Exiting the installer.')" && end_message && exit 1
    fi
}

_install() {
    local version_code repo_url gpgkey_url

    pre_check
    clean_repo_files

    _info_msg "$(_yellow 'Installing the Docker environment!')"
    if [ "$os_name" = "rocky" ] || [ "$os_name" = "almalinux" ] || [ "$os_name" = "centos" ]; then
        pkg_uninstall docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine >/dev/null 2>&1

        if [ "$_loc" = "CN" ]; then
            repo_url="https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo"
        else
            repo_url="https://download.docker.com/linux/centos/docker-ce.repo"
        fi

        if _exists dnf >/dev/null 2>&1; then
            if ! dnf config-manager --help >/dev/null 2>&1; then
                dnf install -y dnf-plugins-core
            fi
            dnf config-manager --add-repo "$repo_url" 2>/dev/null
            dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        elif _exists yum >/dev/null 2>&1; then
            if ! rpm -q yum-utils >/dev/null 2>&1; then
                yum install -y yum-utils
            fi
            yum-config-manager --add-repo "$repo_url" >/dev/null 2>&1
            yum makecache fast
            yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        else
            _err_msg "$(_red 'Unknown package manager!')" && end_message && exit 1
        fi

        systemctl enable docker
        systemctl start docker
    elif [ "$os_name" = "rhel" ]; then
        pkg_uninstall docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine podman runc >/dev/null 2>&1

        if ! dnf config-manager --help >/dev/null 2>&1; then
            dnf install -y dnf-plugins-core
        fi

        if [ "$_loc" = "CN" ]; then
            dnf config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/rhel/docker-ce.repo
        else
            dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
        fi

        dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        systemctl enable docker
        systemctl start docker
    elif [ "$os_name" = "debian" ] || [ "$os_name" = "ubuntu" ]; then
        version_code="$(grep "^VERSION_CODENAME" /etc/*-release | cut -d= -f2)"
        pkg_uninstall docker.io docker-doc docker-compose podman-docker containerd runc >/dev/null 2>&1

        if [ "$_loc" = "CN" ]; then
            repo_url="https://mirrors.aliyun.com/docker-ce/linux/${os_name}"
            gpgkey_url="https://mirrors.aliyun.com/docker-ce/linux/${os_name}/gpg"
        else
            repo_url="https://download.docker.com/linux/${os_name}"
            gpgkey_url="https://download.docker.com/linux/${os_name}/gpg"
        fi

        fix_dpkg
        apt-get -qq update
        apt-get install -y -qq ca-certificates curl
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL "$gpgkey_url" -o /etc/apt/keyrings/docker.asc
        chmod a+r /etc/apt/keyrings/docker.asc

        # add the repository to apt sources
        echo "deb [arch=$( dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] $repo_url $version_code stable" |  tee /etc/apt/sources.list.d/docker.list >/dev/null
        apt-get -qq update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        systemctl enable docker
        systemctl start docker
    elif [ "$os_name" = "alpine" ]; then
        [ "$_loc" = "CN" ] && sed -i -E 's|^https?://dl-cdn.alpinelinux.org|https://mirrors.aliyun.com|g' /etc/apk/repositories 2>/dev/null
        apk update
        apk add docker docker-compose
        systemctl enable docker
        systemctl start docker
    else
        _err_msg "$(_red 'The current operating system is not supported!')" && end_message && exit 1
    fi
}

_uninstall() {
    local depend_datadir=("/var/lib/docker" "/var/lib/containerd" "/etc/docker" "/opt/containerd")
    local depend_files=("/etc/yum.repos.d/docker*" "/etc/apt/sources.list.d/docker.*" "/etc/apt/keyrings/docker.*" "/var/log/docker.*")
    local bin_files=("/usr/bin/docker" "/usr/bin/docker-compose")
    local uninstall_depend_pkg=("docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin")

    # 检查Docker是否安装
    if ! _exists docker >/dev/null 2>&1; then
        _err_msg "$(_red 'Docker is not installed on the system, unable to proceed with uninstallation.')" && return 1
    fi

    # 停止并删除Docker服务和容器
    if docker ps -a -q >/dev/null 2>&1; then
        docker rm -f "$(docker ps -a -q)" 2>/dev/null
    fi
    systemctl stop docker.socket docker 2>/dev/null || true
    systemctl stop docker || true
    systemctl disable docker 2>/dev/null || true

    # 卸载相关软件包
    for pkg in "${uninstall_depend_pkg[@]}"; do
        if _exists "$pkg"; then
            pkg_uninstall "$pkg"
        fi
    done

    # 清理文件和目录
    rm -f "${depend_files[@]}" 2>/dev/null || true
    rm -rf "${depend_datadir[@]}" "${bin_files[@]}" 2>/dev/null

    # 刷新命令缓存
    hash -r
    sleep 2

    if _exists docker >/dev/null 2>&1 || [ -e "/usr/bin/docker" ]; then
        _err_msg "$(_red 'Docker uninstallation failed. Please check manually.')" && return 1
    else
        _suc_msg "Docker and Docker Compose uninstalled, folders and dependencies cleaned."
    fi
}

_version() {
    local docker_v=""
    local docker_compose_v=""

    # 获取Docker版本
    if _exists docker >/dev/null 2>&1; then
        docker_v=$(docker --version | awk -F '[ ,]' '{print $3}')
    elif _exists docker.io >/dev/null 2>&1; then
        docker_v=$(docker.io --version | awk -F '[ ,]' '{print $3}')
    fi

    # 获取Docker Compose版本
    if docker compose version >/dev/null 2>&1; then
        docker_compose_v=$(docker compose version --short)
    elif _exists docker-compose >/dev/null 2>&1; then
        docker_compose_v=$(docker-compose version --short)
    fi

    echo
    echo "Docker Version: v${docker_v}"
    echo "Docker Compose Version: v${docker_compose_v}"
    echo
    _yellow "Get Docker information"
    sleep 2
    docker version 2>/dev/null

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
    if "$systemctl_cmd" is-active --quiet docker || \
        docker info >/dev/null 2>&1 || \
        /etc/init.d/docker status | grep -q 'started' || \
        service docker status >/dev/null 2>&1 || \
        curl -s --unix-socket /var/run/docker.sock http://localhost/version >/dev/null 2>&1; then
            _suc_msg "$(_green 'Docker has completed self-check, started, and set to start on boot!')"
    else
        _err_msg "$(_red 'Docker status check failed or service not starting. Check logs or start Docker manually.')" && end_message && exit 1
    fi
}

docker_install() {
    clear
    _show_logo
    os_permission
    virt_permission
    _check_install
    _install
    _version
    _status
    end_message
}

docker_uninstall() {
    clear
    _show_logo
    os_permission
    virt_permission
    _uninstall
    end_message
}

if [ "$#" -eq 0 ]; then
    docker_install
else
    while [ "$#" -ge 1 ]; do
        case "$1" in
            --install)
                docker_install
                shift 1
            ;;
            --uninstall)
                docker_uninstall
                shift 1
            ;;
            *) _err_msg "$(_red "Invalid option, current parameter $1 Not supported!")" && end_message && _show_usage ;;
        esac
    done
fi