#!/usr/bin/env bash
#
# Description: Gather system information, test disk I/O, and assess network performance to China.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# Thanks: Teddysun <i@teddysun.com>
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

# 当前脚本版本号
readonly version='v0.1.7 (2025.03.02)'

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

_err_msg() { echo -e "\033[41m\033[1mwarn${white} $*"; }

# 分割符
separator() { printf "%-70s\n" "-" | sed 's/\s/-/g'; }

# 预定义常量
github_Proxy='https://gh-proxy.com/'
temp_Dir='/tmp/bench'
speedtest_Dir="$temp_Dir/speedtest"

# 定义一个数组存储用户未安装的软件包
declare -a uninstall_depend_pkg=()

_exit() {
    rm -rf "$temp_Dir"
    if [ ${#uninstall_depend_pkg[@]} -gt 0 ]; then
        (for pkg in "${uninstall_depend_pkg[@]}"; do pkg_uninstall "$pkg" >/dev/null 2>&1; done) & disown
    fi
    exit 0
}

trap "_exit" SIGINT SIGQUIT SIGTERM EXIT

mkdir -p "$temp_Dir"

print_title() {
    echo "--------------------- A Bench.sh Script By honeok --------------------"
    echo " Version            : $(_green "$version") $(_purple "\xf0\x9f\x92\x80")"
    echo " $(_cyan 'bash <(curl -sL https://github.com/honeok/cross/raw/master/bench.sh)')"
}

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
        elif _exists apk; then
            apk add --no-cache "$package"
        elif _exists pacman; then
            pacman -S --noconfirm --needed "$package"
        elif _exists zypper; then
            zypper install -y "$package"
        elif _exists opkg; then
            opkg install "$package"
        elif _exists pkg; then
            pkg install -y "$package"
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
        elif _exists apk; then
            apk del "$package"
        elif _exists pacman; then
            pacman -Rns --noconfirm "$package"
        elif _exists zypper; then
            zypper remove -y "$package"
        elif _exists opkg; then
            opkg remove "$package"
        elif _exists pkg; then
            pkg delete -y "$package"
        fi
    done
}

# 运行前校验
pre_check() {
    local install_depend_pkg
    install_depend_pkg=( "curl" "tar" "bc" )

    if [ "$(id -ru)" -ne "0" ]; then
        _err_msg "$(_red 'Error: This script must be run as root!')" && exit 1
    fi
    if [ "$(ps -p $$ -o comm=)" != "bash" ]; then
        _err_msg "$(_red 'Error: This script needs to be run with bash, not sh!')" && exit 1
    fi
    for pkg in "${install_depend_pkg[@]}"; do
        if ! _exists "$pkg" >/dev/null 2>&1; then
            uninstall_depend_pkg+=("$pkg")
            pkg_install "$pkg"
        fi
    done
    if [ "$(curl -fskL "https://www.qualcomm.cn/cdn-cgi/trace" | grep -i '^loc=' | cut -d'=' -f2 | xargs)" != "CN" ]; then
        github_Proxy=''
    fi
    # 脚本当天及累计运行次数统计
    runcount=$(curl -fskL -m 2 --retry 1 "https://hit.forvps.gq/https://github.com/honeok/cross/raw/master/bench.sh" 2>&1 | grep -m1 -oE "[0-9]+[ ]+/[ ]+[0-9]+")

    start_time=$(date +%s)
}

to_kibyte() {
    awk "BEGIN {printf \"%.0f\", $1 / 1024}"
}

calc_sum() {
    local sum=0
    for num in "$@"; do
        sum=$(( sum + num ))
    done
    echo "$sum"
}

format_size() {
    # 获取字节
    local bytes="$1"
    local size=0
    local divisor=1
    local unit="KB"

    # 检查输入是否为非负整数
    if echo "$bytes" | grep -vE '^[0-9]+$' >/dev/null 2>&1; then
        return 1
    fi
    # 根据字节数大小选择单位和除数
    if [ "$bytes" -ge 1073741824 ]; then
        divisor=1073741824
        unit="TB"
    elif [ "$bytes" -ge 1048576 ]; then
        divisor=1048576
        unit="GB"
    elif [ "$bytes" -ge 1024 ]; then
        divisor=1024
        unit="MB"
    elif [ "$bytes" -eq 0 ]; then
        echo "$size"
        return 0
    fi
    # 计算并格式化结果保留一位小数
    size=$(awk "BEGIN {printf \"%.1f\", $bytes / $divisor}")
    echo "$size $unit"
}

# 获取系统信息
obtain_system_info() {
    # CPU信息
    cpu_model=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
    cpu_cores=$(awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo 2>/dev/null)
    cpu_frequency=$(awk -F: '/cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
    cpu_cache=$(awk -F: '/cache size/ {cache=$2} END {print cache}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
    cpu_aes=$(grep -i 'aes' /proc/cpuinfo) # 检查AES-NI指令集支持
    cpu_virt=$(grep -Ei 'vmx|svm' /proc/cpuinfo) # 检查VM-x/AMD-V支持

    # 内存和交换空间
    tram=$(format_size "$(free -k | awk '/Mem/ {print $2}')")
    uram=$(format_size "$(free -k | awk '/Mem/ {print $3}')")
    swap=$(format_size "$(free -k | awk '/Swap/ {print $2}')")
    uswap=$(format_size "$(free -k | awk '/Swap/ {print $3}')")

    # 系统运行时间
    uptime_str=$(awk '{printf "%d days, %d hr %d min\n", $1/86400, ($1%86400)/3600, ($1%3600)/60}' /proc/uptime)
    # 系统负载
    if _exists "w"; then
        load_average=$(w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
    elif _exists "uptime"; then
        load_average=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1, $2, $3}')
    fi

    # 系统基本信息
    if _exists "lsb_release" >/dev/null 2>&1; then
        os_release=$(lsb_release -d | awk -F: '{print $2}' | xargs | sed 's/ (.*)//')
    elif [ -f /etc/redhat-release ]; then
        os_release=$(awk '{print ($1, $3~/^[0-9]/ ? $3 : $4)}' /etc/redhat-release)
    elif [ -f /etc/os-release ]; then
        os_release=$(awk -F'[= "]' '/PRETTY_NAME/{print $3, $4, $5}' /etc/os-release)
    elif [ -f /etc/lsb-release ]; then
        os_release=$(awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release)
    else
        os_release="Unknown OS"
    fi
    cpu_architecture=$(uname -m 2>/dev/null || lscpu | awk -F ': +' '/Architecture/{print $2}' || echo "Full Unknown")
    if _exists "getconf"; then
        sys_bits=$(getconf LONG_BIT)
    else
        echo "$cpu_architecture" | grep -q "64" && sys_bits="64" || sys_bits="32"
    fi
    if _exists "hostnamectl"; then
        kernel_version=$(hostnamectl | sed -n 's/^.*Kernel: Linux //p')
    else
        kernel_version=$(uname -r)
    fi

    # 磁盘大小 (包含swap和ZFS)
    in_kernel_no_swap_total_size=$(df -t simfs -t ext2 -t ext3 -t ext4 -t btrfs -t xfs -t vfat -t ntfs --total 2>/dev/null | awk '/total/ {print $2}')
    swap_total_size=$(free -k | awk '/Swap/ {print $2}')
    zfs_total_size=$(to_kibyte "$(calc_sum "$(zpool list -o size -Hp 2>/dev/null)")")
    disk_total_size=$(format_size $((swap_total_size + in_kernel_no_swap_total_size + zfs_total_size)))

    in_kernel_no_swap_used_size=$(df -t simfs -t ext2 -t ext3 -t ext4 -t btrfs -t xfs -t vfat -t ntfs --total 2>/dev/null | awk '/total/ {print $3}')
    swap_used_size=$(free -k | awk '/Swap/ {print $3}')
    zfs_used_size=$(to_kibyte "$(calc_sum "$(zpool list -o allocated -Hp 2>/dev/null)")")
    disk_used_size=$(format_size $((swap_used_size + in_kernel_no_swap_used_size + zfs_used_size)))

    # 获取网络拥塞控制算法
    # 获取队列算法
    if _exists "sysctl"; then
        congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
        queue_algorithm=$(sysctl -n net.core.default_qdisc 2>/dev/null)
    fi
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

# IP双栈检查
ip_dual_stack() {
    local ipv4_check ipv6_check

    if ping -4 -c 1 -W 4 1.1.1.1 >/dev/null 2>&1; then
        ipv4_check="true"
    else
        ipv4_check=$(curl -sL -m 4 -4 ipinfo.io/ip 2>/dev/null)
    fi
    if ping -6 -c 1 -W 4 2606:4700:4700::1111 >/dev/null 2>&1; then
        ipv6_check="true"
    else
        ipv6_check=$(curl -sL -m 4 -6 v6.ipinfo.io/ip 2>/dev/null)
    fi

    if [ -z "$ipv4_check" ] && [ -z "$ipv6_check" ]; then
        _yellow "Warning: Both IPv4 and IPv6 connectivity were not detected."
    fi
    if [ -n "$ipv4_check" ]; then
        online=$(_green "\xe2\x9c\x93 Online")
    else
        online=$(_red "\xe2\x9c\x97 Offline")
    fi
    if [ -n "$ipv6_check" ]; then
        online+=" / $(_green "\xe2\x9c\x93 Online")"
    else
        online+=" / $(_red "\xe2\x9c\x97 Offline")"
    fi
}

# 打印系统信息
print_system_info() {
    if [ -n "$cpu_model" ]; then
        echo " CPU Model          : $(_cyan "$cpu_model")"
    else
        echo " CPU Model          : $(_cyan "CPU model not detected")"
    fi
    if [ -n "$cpu_frequency" ]; then
        echo " CPU Cores          : $(_cyan "$cpu_cores @ $cpu_frequency MHz")"
    else
        echo " CPU Cores          : $(_cyan "$cpu_cores")"
    fi
    if [ -n "$cpu_cache" ]; then
        echo " CPU Cache          : $(_cyan "$cpu_cache")"
    fi
    if [ -n "$cpu_aes" ]; then
        echo " AES-NI             : $(_green "\xe2\x9c\x93 Enabled")"
    else
        echo " AES-NI             : $(_red "\xe2\x9c\x97 Disabled")"
    fi
    if [ -n "$cpu_virt" ]; then
        echo " VM-x/AMD-V         : $(_green "\xe2\x9c\x93 Enabled")"
    else
        echo " VM-x/AMD-V         : $(_red "\xe2\x9c\x97 Disabled")"
    fi
    echo " Total Disk         : $(_yellow "$disk_total_size") $(_cyan "($disk_used_size Used)")"
    echo " Total Mem          : $(_yellow "$tram") $(_cyan "($uram Used)")"
    if [ "$swap" != "0" ]; then
        echo " Total Swap         : $(_cyan "$swap ($uswap Used)")"
    fi
    echo " System uptime      : $(_cyan "$uptime_str")"
    echo " Load average       : $(_cyan "$load_average")"
    echo " OS                 : $(_cyan "$os_release")"
    echo " Arch               : $(_cyan "$cpu_architecture ($sys_bits Bit)")"
    echo " Kernel             : $(_cyan "$kernel_version")"
    echo " TCP CC             : $(_yellow "$congestion_algorithm $queue_algorithm")"
    echo " Virtualization     : $(_cyan "$virt_type")"
    echo " IPv4/IPv6          : $online"
}

# 获取当前IP相关信息
ip_details() {
    local ipinfo_result ip_org ip_city ip_country ip_region

    ipinfo_result=$(curl -fskL -m 10 ipinfo.io)
    ip_org=$(echo "$ipinfo_result" | awk -F'"' '/"org":/ {print $4}')
    ip_city=$(echo "$ipinfo_result" | awk -F'"' '/"city":/ {print $4}')
    ip_country=$(echo "$ipinfo_result" | awk -F'"' '/"country":/ {print $4}')
    ip_region=$(echo "$ipinfo_result" | awk -F'"' '/"region":/ {print $4}')

    if [ -n "$ip_org" ]; then
        echo " Organization       : $(_cyan "$ip_org")"
    fi
    if [ -n "$ip_city" ] && [ -n "$ip_country" ]; then
        echo " Location           : $(_cyan "$ip_city / $ip_country")"
    fi
    if [ -n "$ip_region" ]; then
        echo " Region             : $(_yellow "$ip_region")"
    fi
    if [ -z "$ip_org" ]; then
        echo " Region             : $(_red "No ISP detected")"
    fi
}

io_test() {
    local speed
    local block_count="$1"

    speed=$(LANG=C dd if=/dev/zero of="$temp_Dir/io_$$" bs=512k count="$block_count" conv=fdatasync 2>&1 | grep -o "[0-9.]\+ [MG]B/s")
    echo "$speed"
}

# 磁盘IO测试
print_io_test() {
    local free_space write_mb io1 io2 io3 speed1 speed2 speed3 ioavg

    free_space=$(df -m . | awk 'NR==2 {print $4}') # 检查可用空间 (MB)
    write_mb=2048  # 每次写入2GB

    # 检查空间是否足够
    if [ "$free_space" -gt 1024 ]; then
        # 运行三次I/O测试
        io1=$(io_test $write_mb)
        echo " I/O Speed(1st run) : $(_yellow "$io1")"
        io2=$(io_test $write_mb)
        echo " I/O Speed(2nd run) : $(_yellow "$io2")"
        io3=$(io_test $write_mb)
        echo " I/O Speed(3rd run) : $(_yellow "$io3")"

        # 提取数值并转换为MB/s
        speed1=$(echo "$io1" | awk '{print $1}')           # 取数字
        [ "$(echo "$io1" | awk '{print $2}')" = "GB/s" ] && speed1=$(echo "$speed1 * 1024" | bc)
        speed2=$(echo "$io2" | awk '{print $1}')
        [ "$(echo "$io2" | awk '{print $2}')" = "GB/s" ] && speed2=$(echo "$speed2 * 1024" | bc)
        speed3=$(echo "$io3" | awk '{print $1}')
        [ "$(echo "$io3" | awk '{print $2}')" = "GB/s" ] && speed3=$(echo "$speed3 * 1024" | bc)

        # 计算平均值
        ioavg=$(echo "$speed1 $speed2 $speed3" | awk '{print ($1 + $2 + $3) / 3}')
        echo " I/O Speed(average) : $(_yellow "$ioavg MB/s")"
    else
        echo " $(_red "Not enough space for I/O Speed test!")"
    fi
}

install_speedtest() {
    local speedtest_ver sys_arch

    speedtest_ver="1.7.9"
    mkdir -p "$speedtest_Dir"

    case "$(uname -m)" in
        'i386' | 'i686')
            sys_arch="i386"
        ;;
        'x86_64')
            sys_arch="x86_64"
        ;;
        'armv6')
            sys_arch="armv6"
        ;;
        'armv7' | 'armv7l')
            sys_arch="armv7"
        ;;
        'armv8' | 'armv8l' | 'aarch64' | 'arm64')
            sys_arch="arm64"
        ;;
        *)
            _err_msg "$(_red "Error: Unsupported system architecture (${sys_arch})")" && exit 1
        ;;
    esac

    if ! curl -fskL -o "$speedtest_Dir/speedtest.tar.gz" "${github_Proxy}https://github.com/showwin/speedtest-go/releases/download/v${speedtest_ver}/speedtest-go_${speedtest_ver}_Linux_${sys_arch}.tar.gz"; then
        _err_msg "$(_red 'Error: Failed to download speedtest-go')" && exit 1
    fi

    tar zxf "$speedtest_Dir/speedtest.tar.gz" -C "$speedtest_Dir"

    printf "%-18s%-18s%-20s%-12s\n" " Node Name" "Upload Speed" "Download Speed" "Latency"
}

# https://github.com/showwin/speedtest-go
speedtest() {
    local upload_speed download_speed latency
    local nodeName="$2"

    if [ -z "$1" ]; then
        "$speedtest_Dir/speedtest-go" --unix > "$speedtest_Dir/speedtest.log" 2>&1 || return
    else
        "$speedtest_Dir/speedtest-go" --unix -s "$1" > "$speedtest_Dir/speedtest.log" 2>&1 || return
    fi

    upload_speed=$(awk -F': ' '/Upload/ {split($2, a, " "); print a[1] " " a[2]; exit}' "$speedtest_Dir/speedtest.log")
    download_speed=$(awk -F': ' '/Download/ {split($2, a, " "); print a[1] " " a[2]; exit}' "$speedtest_Dir/speedtest.log")
    latency=$(awk '/Latency:/ {sub(/ms$/, "", $2); printf "%.2fms", $2; exit}' "$speedtest_Dir/speedtest.log")

    if [ -n "$download_speed" ] && [ -n "$upload_speed" ] && [ -n "$latency" ]; then
        printf "${yellow}%-18s${green}%-18s${red}%-20s${cyan}%-12s${white}\n" " $nodeName" "$upload_speed" "$download_speed" "$latency"
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
    local end_time time_count min sec today_runcount total_runcount

    end_time=$(date +%s)
    time_count=$(( end_time - start_time ))

    if [ "$time_count" -gt 60 ]; then
        min=$(( time_count / 60 ))
        sec=$(( time_count % 60 ))
        echo " Finished in        : $min min $sec sec"
    else
        echo " Finished in        : $time_count sec"
    fi
    if [ -n "$runcount" ]; then
        today_runcount=$(awk -F ' ' '{print $1}' <<< "$runcount")
        total_runcount=$(awk -F ' ' '{print $3}' <<< "$runcount")
        echo " Runs (Today/Total) : $today_runcount / $total_runcount"
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