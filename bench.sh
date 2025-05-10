#!/usr/bin/env bash
#
# Description: Gather system information, test disk I/O, and assess network performance to China.
#
# Copyright (c) 2025 honeok <honeok@duck.com>
#
# Thanks: Teddysun <i@teddysun.com>
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

# 当前脚本版本号
readonly VERSION='v0.1.11 (2025.05.10)'

red='\033[91m'
green='\033[92m'
yellow='\033[93m'
purple='\033[95m'
cyan='\033[96m'
white='\033[0m'
_red() { echo -e "$red$*$white"; }
_green() { echo -e "$green$*$white"; }
_yellow() { echo -e "$yellow$*$white"; }
_purple() { echo -e "$purple$*$white"; }
_cyan() { echo -e "$cyan$*$white"; }
_err_msg() { echo -e "\033[41m\033[1mError$white $*"; }

# https://www.graalvm.org/latest/reference-manual/ruby/UTF8Locale
if locale -a 2>/dev/null | grep -qiE -m 1 "UTF-8|utf8"; then
    export LANG=en_US.UTF-8
fi

# 环境变量用于在debian或ubuntu操作系统中设置非交互式 (noninteractive) 安装模式
export DEBIAN_FRONTEND=noninteractive

# 分割符
separator() { printf "%-70s\n" "-" | sed 's/\s/-/g'; }

# 各变量默认值
GITHUB_PROXY='https://gh-proxy.com/'
TEMP_DIR='/tmp/bench'
SPEEDTEST_DIR="$TEMP_DIR/speedtest"
UA_BROWSER='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36'

declare -a CURL_OPTS=(-m 5 --retry 1 --retry-max-time 10)
declare -a UNINSTALL_PKG=()
declare -a ONLINE=()

_exit() {
    local RETURN_VALUE="$?"

    rm -rf "$TEMP_DIR" >/dev/null 2>&1
    if [ ${#UNINSTALL_PKG[@]} -gt 0 ]; then
        (for pkg in "${UNINSTALL_PKG[@]}"; do pkg_uninstall "$pkg" >/dev/null 2>&1; done) & disown
    fi
    exit "$RETURN_VALUE"
}

trap '_exit' SIGINT SIGQUIT SIGTERM EXIT

mkdir -p "$TEMP_DIR" >/dev/null 2>&1

print_title() {
    echo "--------------------- A Bench.sh Script By honeok --------------------"
    echo " Version            : $(_green "$VERSION") $(_purple "\xF0\x9F\x9A\x80")"
    echo " $(_cyan 'bash <(curl -sL https://github.com/honeok/cross/raw/master/bench.sh)')"
}

_exists() {
    local _CMD="$1"
    if type "$_CMD" >/dev/null 2>&1; then
        return 0
    elif command -v "$_CMD" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

pkg_install() {
    for pkg in "$@"; do
        _yellow "Installing $pkg"
        if _exists dnf; then
            dnf install -y "$pkg"
        elif _exists yum; then
            yum install -y "$pkg"
        elif _exists apt-get; then
            apt-get install -y -q "$pkg"
        elif _exists apt; then
            apt install -y -q "$pkg"
        elif _exists apk; then
            apk add --no-cache "$pkg"
        elif _exists pacman; then
            pacman -S --noconfirm --needed "$pkg"
        elif _exists zypper; then
            zypper install -y "$pkg"
        elif _exists opkg; then
            opkg install "$pkg"
        elif _exists pkg; then
            pkg install -y "$pkg"
        else
            _err_msg "$(_red 'The package manager is not supported.')" && exit 1
        fi
    done
}

pkg_uninstall() {
    for pkg in "$@"; do
        if _exists dnf; then
            dnf remove -y "$pkg"
        elif _exists yum; then
            yum remove -y "$pkg"
        elif _exists apt-get; then
            apt-get purge -y "$pkg"
        elif _exists apt; then
            apt purge -y "$pkg"
        elif _exists apk; then
            apk del "$pkg"
        elif _exists pacman; then
            pacman -Rns --noconfirm "$pkg"
        elif _exists zypper; then
            zypper remove -y "$pkg"
        elif _exists opkg; then
            opkg remove "$pkg"
        elif _exists pkg; then
            pkg delete -y "$pkg"
        fi
    done
}

# 运行前校验
pre_check() {
    local INSTALL_PKG
    INSTALL_PKG=("tar" "bc")

    # 备用 www.prologis.cn
    # 备用 www.autodesk.com.cn
    # 备用 www.keysight.com.cn
    CLOUDFLARE_API="www.qualcomm.cn"

    if [ "$(id -ru)" -ne 0 ] || [ "$EUID" -ne 0 ]; then
        _err_msg "$(_red 'This script must be run as root!')" && exit 1
    fi
    if [ "$(ps -p $$ -o comm=)" != "bash" ] || readlink /proc/$$/exe | grep -q "dash"; then
        _err_msg "$(_red 'This script needs to be run with bash, not sh!')" && exit 1
    fi
    # 安装必要的软件包
    for pkg in "${INSTALL_PKG[@]}"; do
        if ! _exists "$pkg" >/dev/null 2>&1; then
            UNINSTALL_PKG+=("$pkg")
            pkg_install "$pkg"
        fi
    done
    # 境外服务器仅ipv4访问测试通过后取消github代理
    if [ "$(curl -A "$UA_BROWSER" -fsSL "${CURL_OPTS[@]}" -4 "https://$CLOUDFLARE_API/cdn-cgi/trace" | grep -i '^loc=' | cut -d'=' -f2 | xargs)" != "CN" ]; then
        unset GITHUB_PROXY
    fi
    # 脚本当天及累计运行次数统计
    RUNCOUNT=$(curl -fsSL "${CURL_OPTS[@]}" -k "https://hits.honeok.com/bench?action=hit")

    START_TIME=$(date +%s)
}

to_kibyte() {
    awk "BEGIN {printf \"%.0f\", $1 / 1024}"
}

calc_sum() {
    local SUM=0
    for num in "$@"; do
        SUM=$((SUM + num))
    done
    echo "$SUM"
}

format_size() {
    # 获取字节
    local BYTES="$1"
    local SIZE=0
    local DIVISOR=1
    local UNIT="KB"

    # 检查输入是否为非负整数
    if echo "$BYTES" | grep -vE '^[0-9]+$' >/dev/null 2>&1; then
        return 1
    fi
    # 根据字节数大小选择单位和除数
    if [ "$BYTES" -ge 1073741824 ]; then
        DIVISOR=1073741824
        UNIT="TB"
    elif [ "$BYTES" -ge 1048576 ]; then
        DIVISOR=1048576
        UNIT="GB"
    elif [ "$BYTES" -ge 1024 ]; then
        DIVISOR=1024
        UNIT="MB"
    elif [ "$BYTES" -eq 0 ]; then
        echo "$SIZE"
        return 0
    fi
    # 计算并格式化结果保留一位小数
    SIZE=$(awk "BEGIN {printf \"%.1f\", $BYTES / $DIVISOR}")
    echo "$SIZE $UNIT"
}

# 获取系统信息
obtain_system_info() {
    # CPU信息
    CPU_MODEL=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
    CPU_CORES=$(awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo 2>/dev/null)
    CPU_FREQUENCY=$(awk -F: '/cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
    CPU_CACHE=$(awk -F: '/cache size/ {cache=$2} END {print cache}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
    CPU_AES=$(grep -i 'aes' /proc/cpuinfo) # 检查AES-NI指令集支持
    CPU_VIRT=$(grep -Ei 'vmx|svm' /proc/cpuinfo) # 检查VM-x/AMD-V支持

    # 内存和交换空间
    TRAM=$(format_size "$(free -k | awk '/Mem/ {print $2}')")
    URAM=$(format_size "$(free -k | awk '/Mem/ {print $3}')")
    SWAP=$(format_size "$(free -k | awk '/Swap/ {print $2}')")
    USWAP=$(format_size "$(free -k | awk '/Swap/ {print $3}')")

    # 系统运行时间
    UPTIME_STR=$(awk '{printf "%d days, %d hr %d min\n", $1/86400, ($1%86400)/3600, ($1%3600)/60}' /proc/uptime)
    # 系统负载
    if _exists "w"; then
        LOAD_AVERAGE=$(w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
    elif _exists "uptime"; then
        LOAD_AVERAGE=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1, $2, $3}')
    fi

    # 系统基本信息
    if _exists "lsb_release" >/dev/null 2>&1; then
        OS_RELEASE=$(lsb_release -d | awk -F: '{print $2}' | xargs | sed 's/ (.*)//')
    elif [ -f /etc/redhat-release ]; then
        OS_RELEASE=$(awk '{print ($1, $3~/^[0-9]/ ? $3 : $4)}' /etc/redhat-release)
    elif [ -f /etc/os-release ]; then
        OS_RELEASE=$(awk -F'[= "]' '/PRETTY_NAME/{print $3, $4, $5}' /etc/os-release)
    elif [ -f /etc/lsb-release ]; then
        OS_RELEASE=$(awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release)
    else
        OS_RELEASE="Unknown OS"
    fi
    CPU_ARCHITECTURE=$(uname -m 2>/dev/null || lscpu | awk -F ': +' '/Architecture/{print $2}' || echo "Full Unknown")
    if _exists "getconf"; then
        SYS_BITS=$(getconf LONG_BIT)
    else
        echo "$CPU_ARCHITECTURE" | grep -q "64" && SYS_BITS="64" || SYS_BITS="32"
    fi
    if _exists "hostnamectl"; then
        KERNEL_VER=$(hostnamectl | sed -n 's/^.*Kernel: Linux //p')
    else
        KERNEL_VER=$(uname -r)
    fi

    # 磁盘大小 (包含swap和ZFS)
    IN_KERNEL_NO_SWAP_TOTAL_SIZE=$(df -t simfs -t ext2 -t ext3 -t ext4 -t btrfs -t xfs -t vfat -t ntfs --total 2>/dev/null | awk '/total/ {print $2}')
    SWAP_TOTAL_SIZE=$(free -k | awk '/Swap/ {print $2}')
    ZFS_TOTAL_SIZE=$(to_kibyte "$(calc_sum "$(zpool list -o size -Hp 2>/dev/null)")")
    DISK_TOTAL_SIZE=$(format_size $((SWAP_TOTAL_SIZE + IN_KERNEL_NO_SWAP_TOTAL_SIZE + ZFS_TOTAL_SIZE)))

    IN_KERNEL_NO_SWAP_USED_SIZE=$(df -t simfs -t ext2 -t ext3 -t ext4 -t btrfs -t xfs -t vfat -t ntfs --total 2>/dev/null | awk '/total/ {print $3}')
    SWAP_USED_SIZE=$(free -k | awk '/Swap/ {print $3}')
    ZFS_USED_SIZE=$(to_kibyte "$(calc_sum "$(zpool list -o allocated -Hp 2>/dev/null)")")
    DISK_USED_SIZE=$(format_size $((SWAP_USED_SIZE + IN_KERNEL_NO_SWAP_USED_SIZE + ZFS_USED_SIZE)))

    # 获取网络拥塞控制算法
    # 获取队列算法
    if _exists "sysctl"; then
        CONGESTION_ALGORITHM=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
        QUEUE_ALGORITHM=$(sysctl -n net.core.default_qdisc 2>/dev/null)
    fi
}

# 虚拟化校验
virt_check() {
    local PROCESSOR_TYPE KERNEL_LOGS SYSTEM_MANUFACTURER SYSTEM_PRODUCT_NAME SYSTEM_VER

    PROCESSOR_TYPE=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')

    if _exists "dmesg" >/dev/null 2>&1; then
        KERNEL_LOGS=$(dmesg)
    fi

    if _exists "dmidecode" >/dev/null 2>&1; then
        SYSTEM_MANUFACTURER=$(dmidecode -s system-manufacturer 2>/dev/null)
        SYSTEM_PRODUCT_NAME=$(dmidecode -s system-product-name 2>/dev/null)
        SYSTEM_VER=$(dmidecode -s system-version 2>/dev/null)
    fi

    if grep -qai docker /proc/1/cgroup; then
        VIRT_TYPE="Docker"
    elif grep -qai lxc /proc/1/cgroup; then
        VIRT_TYPE="LXC"
    elif grep -qai container=lxc /proc/1/environ; then
        VIRT_TYPE="LXC"
    elif [ -f /proc/user_beancounters ]; then
        VIRT_TYPE="OpenVZ"
    elif echo "$KERNEL_LOGS" | grep -qi "kvm-clock" 2>/dev/null; then
        VIRT_TYPE="KVM"
    elif echo "$PROCESSOR_TYPE" | grep -qi "kvm" 2>/dev/null; then
        VIRT_TYPE="KVM"
    elif echo "$PROCESSOR_TYPE" | grep -qi "qemu" 2>/dev/null; then
        VIRT_TYPE="KVM"
    elif grep -qi "kvm" "/sys/devices/virtual/dmi/id/product_name" 2>/dev/null; then
        VIRT_TYPE="KVM"
    elif grep -qi "qemu" "/proc/scsi/scsi" 2>/dev/null; then
        VIRT_TYPE="KVM"
    elif echo "$SYSTEM_MANUFACTURER" | grep -qi "Google" 2>/dev/null && echo "$SYSTEM_PRODUCT_NAME" | grep -qi "Google Compute Engine" 2>/dev/null; then
        VIRT_TYPE="Google"
    elif echo "$KERNEL_LOGS" | grep -qi "Google Compute Engine" 2>/dev/null; then
        VIRT_TYPE="Google"
    elif curl --connect-timeout 1 -s http://metadata.google.internal >/dev/null 2>&1; then
        VIRT_TYPE="Google"
    elif echo "$KERNEL_LOGS" | grep -qi "vmware virtual platform" 2>/dev/null; then
        VIRT_TYPE="VMware"
    elif echo "$KERNEL_LOGS" | grep -qi "parallels software international" 2>/dev/null; then
        VIRT_TYPE="Parallels"
    elif echo "$KERNEL_LOGS" | grep -qi "virtualbox" 2>/dev/null; then
        VIRT_TYPE="VirtualBox"
    elif [ -e /proc/xen ]; then
        if grep -qi "control_d" "/proc/xen/capabilities" 2>/dev/null; then
            VIRT_TYPE="Xen-Dom0"
        else
            VIRT_TYPE="Xen-DomU"
        fi
    elif [ -f "/sys/hypervisor/type" ] && grep -qi "xen" "/sys/hypervisor/type" 2>/dev/null; then
        VIRT_TYPE="Xen"
    elif echo "$SYSTEM_MANUFACTURER" | grep -qi "microsoft corporation" 2>/dev/null; then
        if echo "$SYSTEM_PRODUCT_NAME" | grep -qi "virtual machine" 2>/dev/null; then
            if echo "$SYSTEM_VER" | grep -qi "7.0" 2>/dev/null || echo "$SYSTEM_VER" | grep -qi "hyper-v" 2>/dev/null; then
                VIRT_TYPE="Hyper-V"
            else
                VIRT_TYPE="Microsoft Virtual Machine"
            fi
        fi
    else
        VIRT_TYPE="Dedicated"
    fi
}

# IP双栈检查
ip_dual_stack() {
    local IPV4_CHECK IPV6_CHECK

    if ping -4 -c 1 -W 4 1.1.1.1 >/dev/null 2>&1; then
        IPV4_CHECK="true"
    else
        IPV4_CHECK=$(curl -A "$UA_BROWSER" -fsSL "${CURL_OPTS[@]}" -4 ipinfo.io/ip 2>/dev/null)
    fi
    if ping -6 -c 1 -W 4 2606:4700:4700::1111 >/dev/null 2>&1; then
        IPV6_CHECK="true"
    else
        IPV6_CHECK=$(curl -A "$UA_BROWSER" -fsSL "${CURL_OPTS[@]}" -6 v6.ipinfo.io/ip 2>/dev/null)
    fi

    if [ -z "$IPV4_CHECK" ] && [ -z "$IPV6_CHECK" ]; then
        _yellow "Warning: Both IPv4 and IPv6 connectivity were not detected."
    fi
    if [ -n "$IPV4_CHECK" ]; then
        ONLINE=("$(_green "\xe2\x9c\x93 Online")")
    else
        ONLINE=("$(_red "\xe2\x9c\x97 Offline")")
    fi
    if [ -n "$IPV6_CHECK" ]; then
        ONLINE+=("/ $(_green "\xe2\x9c\x93 Online")")
    else
        ONLINE+=("/ $(_red "\xe2\x9c\x97 Offline")")
    fi
}

# 打印系统信息
print_system_info() {
    if [ -n "$CPU_MODEL" ]; then
        echo " CPU Model          : $(_cyan "$CPU_MODEL")"
    else
        echo " CPU Model          : $(_cyan "CPU model not detected")"
    fi
    if [ -n "$CPU_FREQUENCY" ]; then
        echo " CPU Cores          : $(_cyan "$CPU_CORES @ $CPU_FREQUENCY MHz")"
    else
        echo " CPU Cores          : $(_cyan "$CPU_CORES")"
    fi
    if [ -n "$CPU_CACHE" ]; then
        echo " CPU Cache          : $(_cyan "$CPU_CACHE")"
    fi
    if [ -n "$CPU_AES" ]; then
        echo " AES-NI             : $(_green "\xe2\x9c\x93 Enabled")"
    else
        echo " AES-NI             : $(_red "\xe2\x9c\x97 Disabled")"
    fi
    if [ -n "$CPU_VIRT" ]; then
        echo " VM-x/AMD-V         : $(_green "\xe2\x9c\x93 Enabled")"
    else
        echo " VM-x/AMD-V         : $(_red "\xe2\x9c\x97 Disabled")"
    fi
    echo " Total Disk         : $(_yellow "$DISK_TOTAL_SIZE") $(_cyan "($DISK_USED_SIZE Used)")"
    echo " Total Mem          : $(_yellow "$TRAM") $(_cyan "($URAM Used)")"
    if [ "$SWAP" != "0" ]; then
        echo " Total Swap         : $(_cyan "$SWAP ($USWAP Used)")"
    fi
    echo " System uptime      : $(_cyan "$UPTIME_STR")"
    echo " Load average       : $(_cyan "$LOAD_AVERAGE")"
    echo " OS                 : $(_cyan "$OS_RELEASE")"
    echo " Arch               : $(_cyan "$CPU_ARCHITECTURE ($SYS_BITS Bit)")"
    echo " Kernel             : $(_cyan "$KERNEL_VER")"
    echo " TCP CC             : $(_yellow "$CONGESTION_ALGORITHM $QUEUE_ALGORITHM")"
    echo " Virtualization     : $(_cyan "$VIRT_TYPE")"
    echo " IPv4/IPv6          : ${ONLINE[*]}"
}

# 获取当前IP相关信息
ip_details() {
    local IPINFO_RESULT IP_ORG IP_CITY IP_COUNTRY IP_REGION

    IPINFO_RESULT=$(curl "${CURL_OPTS[@]}" -fsL http://ipinfo.io)
    IP_ORG=$(echo "$IPINFO_RESULT" | awk -F'"' '/"org":/ {print $4}')
    IP_CITY=$(echo "$IPINFO_RESULT" | awk -F'"' '/"city":/ {print $4}')
    IP_COUNTRY=$(echo "$IPINFO_RESULT" | awk -F'"' '/"country":/ {print $4}')
    IP_REGION=$(echo "$IPINFO_RESULT" | awk -F'"' '/"region":/ {print $4}')

    if [ -n "$IP_ORG" ]; then
        echo " Organization       : $(_cyan "$IP_ORG")"
    fi
    if [ -n "$IP_CITY" ] && [ -n "$IP_COUNTRY" ]; then
        echo " Location           : $(_cyan "$IP_CITY / $IP_COUNTRY")"
    fi
    if [ -n "$IP_REGION" ]; then
        echo " Region             : $(_yellow "$IP_REGION")"
    fi
    if [ -z "$IP_ORG" ]; then
        echo " Region             : $(_red "No ISP detected")"
    fi
}

io_test() {
    local SPEED
    local BLOCK_COUNT="$1"

    SPEED=$(LANG=C dd if=/dev/zero of="$TEMP_DIR/io_$$" bs=512k count="$BLOCK_COUNT" conv=fdatasync 2>&1 | grep -o "[0-9.]\+ [MG]B/s")
    echo "$SPEED"
}

# 磁盘IO测试
print_io_test() {
    local FREE_SPACE WRITE_MB IO1 IO2 IO3 SPEED1 SPEED2 SPEED3 IOAVG

    FREE_SPACE=$(df -m . | awk 'NR==2 {print $4}') # 检查可用空间 (MB)
    WRITE_MB=2048  # 每次写入2GB

    # 检查空间是否足够
    if [ "$FREE_SPACE" -gt 1024 ]; then
        # 运行三次I/O测试
        IO1=$(io_test $WRITE_MB)
        echo " I/O Speed(1st run) : $(_yellow "$IO1")"
        IO2=$(io_test $WRITE_MB)
        echo " I/O Speed(2nd run) : $(_yellow "$IO2")"
        IO3=$(io_test $WRITE_MB)
        echo " I/O Speed(3rd run) : $(_yellow "$IO3")"

        # 提取数值并转换为MB/s
        SPEED1=$(echo "$IO1" | awk '{print $1}')           # 取数字
        [ "$(echo "$IO1" | awk '{print $2}')" = "GB/s" ] && SPEED1=$(echo "$SPEED1 * 1024" | bc)
        SPEED2=$(echo "$IO2" | awk '{print $1}')
        [ "$(echo "$IO2" | awk '{print $2}')" = "GB/s" ] && SPEED2=$(echo "$SPEED2 * 1024" | bc)
        SPEED3=$(echo "$IO3" | awk '{print $1}')
        [ "$(echo "$IO3" | awk '{print $2}')" = "GB/s" ] && SPEED3=$(echo "$SPEED3 * 1024" | bc)

        # 计算平均值
        IOAVG=$(echo "$SPEED1 $SPEED2 $SPEED3" | awk '{print ($1 + $2 + $3) / 3}')
        echo " I/O Speed(average) : $(_yellow "$IOAVG MB/s")"
    else
        echo " $(_red 'Not enough space for I/O Speed test!')"
    fi
}

install_speedtest() {
    local SPEEDTEST_VER SYS_ARCH

    SPEEDTEST_VER=$(curl -A "$UA_BROWSER" "${CURL_OPTS[@]}" -fsSL "https://api.github.com/repos/showwin/speedtest-go/releases/latest" | awk -F '["v]' '/tag_name/{print $5}')
    SPEEDTEST_VER=${SPEEDTEST_VER:-1.7.10}
    mkdir -p "$SPEEDTEST_DIR"

    case "$(uname -m)" in
        i*86)
            SYS_ARCH="i386"
        ;;
        x86_64|amd64)
            SYS_ARCH="x86_64"
        ;;
        armv5*)
            SYS_ARCH="armv5"
        ;;
        armv6*)
            SYS_ARCH="armv6"
        ;;
        armv7*)
            SYS_ARCH="armv7"
        ;;
        armv8* | arm64 | aarch64)
            SYS_ARCH="arm64"
        ;;
        s390x)
            SYS_ARCH="s390x"
        ;;
        *)
            _err_msg "$(_red "Unsupported system architecture: $(uname -m)")" && exit 1
        ;;
    esac

    if ! curl -fsSL -o "$SPEEDTEST_DIR/speedtest.tar.gz" "${GITHUB_PROXY}https://github.com/showwin/speedtest-go/releases/download/v${SPEEDTEST_VER}/speedtest-go_${SPEEDTEST_VER}_Linux_${SYS_ARCH}.tar.gz"; then
        _err_msg "$(_red 'Failed to download speedtest-go')" && exit 1
    fi

    tar zxf "$SPEEDTEST_DIR/speedtest.tar.gz" -C "$SPEEDTEST_DIR"

    printf "%-18s%-18s%-20s%-12s\n" " Node Name" "Upload Speed" "Download Speed" "Latency"
}

# https://github.com/showwin/speedtest-go
speedtest() {
    local UPLOAD_SPEED DOWNLOAD_SPEED LATENCY
    local NODENAME="$2"

    if [ -z "$1" ]; then
        "$SPEEDTEST_DIR/speedtest-go" --unix > "$SPEEDTEST_DIR/speedtest.log" 2>&1 || return
    else
        "$SPEEDTEST_DIR/speedtest-go" --unix -s "$1" > "$SPEEDTEST_DIR/speedtest.log" 2>&1 || return
    fi

    UPLOAD_SPEED=$(awk -F': ' '/Upload/ {split($2, a, " "); print a[1] " " a[2]; exit}' "$SPEEDTEST_DIR/speedtest.log")
    DOWNLOAD_SPEED=$(awk -F': ' '/Download/ {split($2, a, " "); print a[1] " " a[2]; exit}' "$SPEEDTEST_DIR/speedtest.log")
    LATENCY=$(awk '/Latency:/ {sub(/ms$/, "", $2); printf "%.2fms", $2; exit}' "$SPEEDTEST_DIR/speedtest.log")

    if [ -n "$DOWNLOAD_SPEED" ] && [ -n "$UPLOAD_SPEED" ] && [ -n "$LATENCY" ]; then
        printf "${yellow}%-18s${green}%-18s${red}%-20s${cyan}%-12s${white}\n" " $NODENAME" "$UPLOAD_SPEED" "$DOWNLOAD_SPEED" "$LATENCY"
    fi
}

run_speedtest() {
    speedtest '' 'Speedtest.net'
    speedtest '65463' 'Hong Kong, HK'
    speedtest '50406' 'Singapore, SG'
    speedtest '62217' 'Tokyo, JP'
    speedtest '67564' 'Seoul, KR'
    speedtest '13516' 'Los Angeles, US'
    speedtest '31120' 'Frankfurt, DE'
    speedtest '57725' 'Warsaw, PL'
    speedtest '54312' 'ZheJiang, CN'
    speedtest '5396' 'JiangSu, CN'
}

print_end_msg() {
    local END_TIME TIME_COUNT MIN SEC TODAY TOTAL

    END_TIME=$(date +%s)
    TIME_COUNT=$((END_TIME - START_TIME))

    if [ "$TIME_COUNT" -gt 60 ]; then
        MIN=$((TIME_COUNT / 60))
        SEC=$((TIME_COUNT % 60))
        echo " Finished in        : $MIN min $SEC sec"
    else
        echo " Finished in        : $TIME_COUNT sec"
    fi
    if [ -n "$RUNCOUNT" ]; then
        TODAY=$(echo "$RUNCOUNT" | grep '"daily"' | sed 's/.*"daily": *\([0-9]*\).*/\1/')
        TOTAL=$(echo "$RUNCOUNT" | grep '"total"' | sed 's/.*"total": *\([0-9]*\).*/\1/')
        echo " Runs (Today/Total) : $TODAY / $TOTAL"
    fi
    echo " Timestamp          : $(date '+%Y-%m-%d %H:%M:%S %Z')"
}

bench() {
    pre_check
    obtain_system_info
    virt_check
    ip_dual_stack
    clear
    print_title
    separator
    print_system_info
    ip_details
    separator
    print_io_test
    separator
    install_speedtest
    run_speedtest
    separator
    print_end_msg
    separator
}

bench