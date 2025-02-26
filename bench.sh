#!/usr/bin/env bash
#
# Description: Collect system info, perform I/O tests, and check network performance to China.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
# Copyright (C) 2021 - 2022 VPS小白 https://vpsxb.net
#
# References:
# https://github.com/teddysun/across/blob/master/bench.sh
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

# shellcheck disable=all

# 当前脚本版本号
readonly version='v1.4.1 (2025.02.26)'

yellow='\033[93m'
red='\033[31m'
green='\033[92m'
blue='\033[94m'
white='\033[0m'
_yellow() { printf "%b%s%b\n" "$yellow" "$*" "$white"; }
_red() { printf "%b%s%b\n" "$red" "$*" "$white"; }
_green() { printf "%b%s%b\n" "$green" "$*" "$white"; }
_blue() { printf "%b%s%b\n" "$blue" "$*" "$white"; }

_err_msg() { printf "%bwarn%b %s\n" "\033[41m\033[1m" "$white" "$*"; }
_suc_msg() { printf "%bsuccess%b %s\n" "\033[42m\033[1m" "$white" "$*"; }

# 预定义常量
github_Proxy='https://gh-proxy.com/'
temp_Dir='/tmp/bench'
log="$temp_Dir/bench.log"
speedLog="$temp_Dir/speedtest.log"
GeekbenchTest='Y'
GeekbenchVer=5
userAgent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.74 Safari/537.36"

: > "$log"
: > "$speedLog"

mkdir -p "$temp_Dir" 1>/dev/null

about() {
    echo "-------------------- A Bench.sh Script By honeok -------------------"
    echo " Version            : $(_green "$version")"
    echo " Usage              : $(_blue 'bash <(curl -sL https://github.com/honeok/cross/raw/master/bench.sh)')"
}

next() {
    printf "%-82s\n" "-" | sed 's/\s/-/g' | tee -a "$log"
}

_exit() {
    echo ""
    next;
    echo " Abort ..."
    echo " Cleanup ..."
    cleanup;
    echo " Done"
    exit 0
}

trap "_exit" SIGINT SIGQUIT SIGTERM EXIT

pkg_install() {
    for pkg in "$@"; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            _yellow "Installing $pkg"
            if command -v dnf >/dev/null 2>&1; then
                dnf -y update
                dnf -y install epel-release
                dnf -y install "$pkg"
            elif command -v yum >/dev/null 2>&1; then
                yum -y update
                yum -y install epel-release
                yum -y install "$pkg"
            elif command -v apt >/dev/null 2>&1; then
                apt -q update
                DEBIAN_FRONTEND=noninteractive apt -y -q install "$pkg"
            elif command -v apt-get >/dev/null 2>&1; then
                apt-get -q update
                DEBIAN_FRONTEND=noninteractive apt-get -y -q install "$pkg"
            elif command -v apk >/dev/null 2>&1; then
                apk add --no-cache "$pkg"
            elif command -v pacman >/dev/null 2>&1; then
                pacman -Syu --noconfirm
                pacman -S --noconfirm --needed "$pkg"
            elif command -v zypper >/dev/null 2>&1; then
                zypper refresh
                zypper -y install "$pkg"
            elif command -v opkg >/dev/null 2>&1; then
                opkg update
                opkg install "$pkg"
            elif command -v pkg >/dev/null 2>&1; then
                pkg update
                pkg -y install "$pkg"
            fi
        else
            _green "$pkg is already installed"
        fi
    done
}

benchInit() {
    local depend_pkg
    depend_pkg=( "wget" "curl" "tar" "unzip" )

    if [ "$(id -ru)" -ne "0" ]; then
        _err_msg "$(_red 'This script must be run as root!')" && exit 1
    fi

    # determine architecture of host
    case "$(uname -m)" in
        x86_64)
            # host is running a 64-bit kernel
            Geekbench_downUrl='https://down.vpsxb.top/superbench/Geekbench-5.4.4-Linux.tar.gz'
            GeekbenchVer=5
        ;;
        *i?86*)
            # host is running a 32-bit kernel
            Geekbench_downUrl='https://down.vpsxb.top/superbench/Geekbench-4.4.4-Linux.tar.gz'
            GeekbenchVer=4
        ;;
        *aarch* | *arm*)
            if [[ $(getconf LONG_BIT 2>/dev/null) == "64" ]]; then
                ARCH='aarch64'
            else
                ARCH='arm'
            fi
            Geekbench_downUrl='https://down.vpsxb.top/superbench/Geekbench-5.4.4-LinuxARMPreview.tar.gz'
            GeekbenchVer=5
            printf "\nARM compatibility is considered *experimental*\n"
        ;;
        *)
            # host is running a non-supported kernel
            _err_msg "$(_red 'Architecture not supported by Superbench.')"
            exit 1
        ;;
    esac

    if ! command -v dmidecode >/dev/null 2>&1; then
        pkg_install dmidecode
    fi

    for pkg in "${depend_pkg[@]}"; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            pkg_install "$pkg"
        fi
    done

    if  [ ! -e "$temp_Dir/speedtest-cli/speedtest" ]; then
        _yellow 'Installing Speedtest-cli'
        curl -fskL -o "$temp_Dir/speedtest.tgz" "https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-$(uname -m).tgz"
    fi
    mkdir -p "$temp_Dir/speedtest-cli" && tar -zxf "$temp_Dir/speedtest.tgz" -C "$temp_Dir/speedtest-cli" >/dev/null 2>&1 && chmod +x "$temp_Dir/speedtest-cli/speedtest"

    if [ ! -f /usr/local/bin/nexttrace ] && [ ! -f /usr/bin/nexttrace ]; then
        bash <(curl -fskL "https://github.com/nxtrace/NTrace-core/raw/main/nt_install.sh")
    fi

    if [[ "$GeekbenchTest" == "Y" ]]; then
        mkdir -p "$temp_Dir/geekbench" 2>/dev/null
        _yellow "Installing Geekbench $GeekbenchVer"
        curl -fskL -o "$temp_Dir/geekbench" "$Geekbench_downUrl" | tar xz --strip-components=1 -C "$temp_Dir/geekbench" >/dev/null 2>&1
        chmod +x "$temp_Dir/geekbench/geekbench$GeekbenchVer"
    fi

    sleep 5

    start=$(date +%s) 
}

get_opsy() {
    grep "^PRETTY_NAME=" /etc/*-release | cut -d '"' -f 2 | sed 's/ (.*)//'
}

speed_test(){
	if [[ $1 == '' ]]; then
		speedtest-cli/speedtest -p no --accept-license --accept-gdpr > $speedLog 2>&1
		is_upload=$(cat $speedLog | grep 'Upload')
		result_speed=$(cat $speedLog | awk -F ' ' '/Result/{print $3}')
		if [[ ${is_upload} ]]; then
	        local REDownload=$(cat $speedLog | awk -F ' ' '/Download/{print $3}')
	        local reupload=$(cat $speedLog | awk -F ' ' '/Upload/{print $3}')
	        local relatency=$(cat $speedLog | awk -F ' ' '/Idle/{print $3}')
			
	        temp=$(echo "$relatency" | awk -F '.' '{print $1}')
        	if [[ ${temp} -gt 50 ]]; then
            	relatency="(*)"${relatency}
        	fi
	        local nodeName=$2

	        temp=$(echo "${REDownload}" | awk -F ' ' '{print $1}')
	        if [[ $(awk -v num1=${temp} -v num2=0 'BEGIN{print(num1>num2)?"1":"0"}') -eq 1 ]]; then
	        	printf "${YELLOW}%-18s${GREEN}%-18s${RED}%-20s${SKYBLUE}%-12s%-20s${PLAIN}\n" " ${nodeName}" "${reupload} Mbit/s" "${REDownload} Mbit/s" "${relatency} ms" | tee -a $log
	        fi
		else
	        local cerror="ERROR"
		fi
	else
		speedtest-cli/speedtest -p no -s $1 --accept-license --accept-gdpr > $speedLog 2>&1
		is_upload=$(cat $speedLog | grep 'Upload')
		if [[ ${is_upload} ]]; then
	        local REDownload=$(cat $speedLog | awk -F ' ' '/Download/{print $3}')
	        local reupload=$(cat $speedLog | awk -F ' ' '/Upload/{print $3}')
	        local relatency=$(cat $speedLog | awk -F ' ' '/Idle/{print $3}')     
	        local nodeName=$2

	        temp=$(echo "${REDownload}" | awk -F ' ' '{print $1}')
	        if [[ $(awk -v num1=${temp} -v num2=0 'BEGIN{print(num1>num2)?"1":"0"}') -eq 1 ]]; then
	        	printf "${YELLOW}%-18s${GREEN}%-18s${RED}%-20s${SKYBLUE}%-12s%-20s${PLAIN}\n" " ${nodeName}" "${reupload} Mbit/s" "${REDownload} Mbit/s" "${relatency} ms" | tee -a $log
			fi
		else
	        local cerror="ERROR"
		fi
	fi
}

print_china_speedtest() {
	printf "%-18s%-18s%-20s%-12s%-20s\n" " Node Name" "Upload Speed" "Download Speed" "Latency" | tee -a $log
    speed_test '' 'Speedtest.net'
	speed_test '25858' 'Beijing      CM'
	speed_test '29105' 'XiAn         CM'
	speed_test '54312' 'Hangzhou     CM'
#	speed_test '26940' 'Yinchuan     CM'
#	speed_test '25637' 'Shanghai 5G  CM'
#	speed_test '27249' 'Nanjing 5G   CM'
#	speed_test '40131' 'Suzhou 5G    CM'
#	speed_test '15863' 'Nanning      CM'
#	speed_test '4575'  'Chengdu      CM'
	speed_test '43752' 'Beijing      CU'
#	speed_test '27154' 'TianJin      CU'
	speed_test '24447' 'Shanghai 5G  CU'
#	speed_test '26678' 'Guangzhou 5G CU'
#	speed_test '16192' 'ShenZhen     CU'
#	speed_test '45170' 'Wu Xi        CU'
#	speed_test '13704' 'Nanjing      CU'
#	speed_test '37235' 'Shenyang     CU'
#	speed_test '41009' 'Wuhan 5G     CU'
#	speed_test '5505'  'Beijing      BN'
	speed_test '5396'  'Suzhou       CT'
#	speed_test '26352' 'Nanjing 5G   CT'
	speed_test '59386' 'Hangzhou     CT'
#    speed_test '59387' 'Ningbo       CT'
#    speed_test '7509'  'Hangzhou     CT'
#	speed_test '23844' 'Wuhan        CT'
}

print_global_speedtest() {
	printf "%-18s%-18s%-20s%-12s%-20s\n" " Node Name" "Upload Speed" "Download Speed" "Latency" | tee -a $log
    speed_test '1536'  'Hong Kong    CN'
    speed_test '25176' 'Macau        CN'
	speed_test '44603' 'Taiwan       CN'
	speed_test '13058' 'Singapore    SG'
#	speed_test '4956'  'Kuala Lumpur MY'
#	speed_test '38134' 'Fukuoka      JP'
	speed_test '21569' 'Tokyo        JP'
	speed_test '6527'  'Seoul        KR'
    speed_test '14236' 'Los Angeles  US'
#	speed_test '15786' 'San Jose     US'
	speed_test '40788' 'London       UK'
	speed_test '54504' 'Frankfurt    DE'
	speed_test '33869' 'France       FR'
}

print_speedtest_fast() {
	printf "%-18s%-18s%-20s%-12s\n" " Node Name" "Upload Speed" "Download Speed" "Latency" | tee -a $log
    speed_test '' 'Speedtest.net'
    speed_test '5396'  'Suzhou       CT'
	speed_test '59386' 'Hangzhou     CT'
    speed_test '26352' 'Nanjing 5G   CT'
	speed_test '43752' 'Beijing      CU'
	speed_test '24447' 'Shanghai 5G  CU'
	speed_test '27154' 'TianJin      CU'
	speed_test '29105' 'Xi An        CM'
	speed_test '25858' 'Beijing      CM'
	speed_test '54312' 'Hangzhou     CM'
	 
	rm -rf speedtest*
}

io_test() {
    (LANG=C dd if=/dev/zero of=test_file_$$ bs=512K count=$1 conv=fdatasync && rm -f test_file_$$ ) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//'
}

calc_disk() {
    local total_size=0
    local array=$@
    for size in ${array[@]}
    do
        [ "${size}" == "0" ] && size_t=0 || size_t=`echo ${size:0:${#size}-1}`
        [ "`echo ${size:(-1)}`" == "K" ] && size=0
        [ "`echo ${size:(-1)}`" == "M" ] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' / 1024}' )
        [ "`echo ${size:(-1)}`" == "T" ] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' * 1024}' )
        [ "`echo ${size:(-1)}`" == "G" ] && size=${size_t}
        total_size=$( awk 'BEGIN{printf "%.1f", '$total_size' + '$size'}' )
    done
    echo ${total_size}
}

power_time() {

	result=$(smartctl -a $(result=$(cat /proc/mounts) && echo $(echo "$result" | awk '/data=ordered/{print $1}') | awk '{print $1}') 2>&1) && power_time=$(echo "$result" | awk '/Power_On/{print $10}') && echo "$power_time"
}

ip_info4(){
	local org="$(wget -q -T10 -O- ipinfo.io/org)"
    local city="$(wget -q -T10 -O- ipinfo.io/city)"
    local country="$(wget -q -T10 -O- ipinfo.io/country)"
    local region="$(wget -q -T10 -O- ipinfo.io/region)"
	if [[ -n "$org" ]]; then
		echo -e " Organization         : ${YELLOW}$org${PLAIN}" | tee -a $log
	fi
	if [[ -n "$city" && -n "country" ]]; then
		echo -e " Location             : ${SKYBLUE}$city / ${YELLOW}$country${PLAIN}" | tee -a $log
	fi
	if [[ -n "$region" ]]; then
		echo -e " Region               : ${SKYBLUE}$region${PLAIN}" | tee -a $log
	fi
}

virt_check(){
	if hash ifconfig 2>/dev/null; then
		eth=$(ifconfig)
	fi

	virtualx=$(dmesg) 2>/dev/null

    if  [[ "$(command -v dmidecode)" != ""  ]]; then
		sys_manu=$(dmidecode -s system-manufacturer) 2>/dev/null
		sys_product=$(dmidecode -s system-product-name) 2>/dev/null
		sys_ver=$(dmidecode -s system-version) 2>/dev/null
	else
		sys_manu=""
		sys_product=""
		sys_ver=""
	fi
	
	if grep docker /proc/1/cgroup -qa; then
	    virtual="Docker"
	elif grep lxc /proc/1/cgroup -qa; then
		virtual="Lxc"
	elif grep -qa container=lxc /proc/1/environ; then
		virtual="Lxc"
	elif [[ -f /proc/user_beancounters ]]; then
		virtual="OpenVZ"
	elif [[ "$virtualx" == *kvm-clock* ]]; then
		virtual="KVM"
	elif [[ "$cname" == *KVM* ]]; then
		virtual="KVM"
	elif [[ "$cname" == *QEMU* ]]; then
		virtual="KVM"
	elif [[ "$virtualx" == *"VMware Virtual Platform"* ]]; then
		virtual="VMware"
	elif [[ "$virtualx" == *"Parallels Software International"* ]]; then
		virtual="Parallels"
	elif [[ "$virtualx" == *VirtualBox* ]]; then
		virtual="VirtualBox"
	elif [[ -e /proc/xen ]]; then
		virtual="Xen"
	elif [[ "$sys_manu" == *"Microsoft Corporation"* ]]; then
		if [[ "$sys_product" == *"Virtual Machine"* ]]; then
			if [[ "$sys_ver" == *"7.0"* || "$sys_ver" == *"Hyper-V" ]]; then
				virtual="Hyper-V"
			else
				virtual="Microsoft Virtual Machine"
			fi
		fi
	else
		virtual="Dedicated"
	fi
}

freedisk() {
	freespace=$( df -m . | awk 'NR==2 {print $4}' )
	if [[ $freespace == "" ]]; then
		$freespace=$( df -m . | awk 'NR==3 {print $3}' )
	fi
	if [[ $freespace -gt 1024 ]]; then
		printf "%s" $((1024*2))
	elif [[ $freespace -gt 512 ]]; then
		printf "%s" $((512*2))
	elif [[ $freespace -gt 256 ]]; then
		printf "%s" $((256*2))
	elif [[ $freespace -gt 128 ]]; then
		printf "%s" $((128*2))
	else
		printf "1"
	fi
}

print_io() {
	if [[ $1 == "fast" ]]; then
		writemb=$((128*2))
	else
		writemb=$(freedisk)
	fi
	
	writemb_size="$(( writemb / 2 ))MB"
	if [[ $writemb_size == "1024MB" ]]; then
		writemb_size="1.0GB"
	fi

	if [[ $writemb != "1" ]]; then
		echo -n " I/O Speed( $writemb_size )   : " | tee -a $log
		io1=$( io_test $writemb )
		echo -e "${YELLOW}$io1${PLAIN}" | tee -a $log
		echo -n " I/O Speed( $writemb_size )   : " | tee -a $log
		io2=$( io_test $writemb )
		echo -e "${YELLOW}$io2${PLAIN}" | tee -a $log
		echo -n " I/O Speed( $writemb_size )   : " | tee -a $log
		io3=$( io_test $writemb )
		echo -e "${YELLOW}$io3${PLAIN}" | tee -a $log
		ioraw1=$( echo $io1 | awk 'NR==1 {print $1}' )
		[ "`echo $io1 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw1=$( awk 'BEGIN{print '$ioraw1' * 1024}' )
		ioraw2=$( echo $io2 | awk 'NR==1 {print $1}' )
		[ "`echo $io2 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw2=$( awk 'BEGIN{print '$ioraw2' * 1024}' )
		ioraw3=$( echo $io3 | awk 'NR==1 {print $1}' )
		[ "`echo $io3 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw3=$( awk 'BEGIN{print '$ioraw3' * 1024}' )
		ioall=$( awk 'BEGIN{print '$ioraw1' + '$ioraw2' + '$ioraw3'}' )
		ioavg=$( awk 'BEGIN{printf "%.1f", '$ioall' / 3}' )
		echo -e " Average I/O Speed    : ${YELLOW}$ioavg MB/s${PLAIN}" | tee -a $log
	else
		echo -e " ${RED}Not enough space!${PLAIN}"
	fi
}

print_system_info() {
	echo -e " CPU Model            : ${SKYBLUE}$cname${PLAIN}" | tee -a $log
	echo -e " CPU Cores            : ${YELLOW}$cores Cores ${SKYBLUE}$freq MHz $arch${PLAIN}" | tee -a $log
	echo -e " CPU Cache            : ${SKYBLUE}$corescache ${PLAIN}" | tee -a $log
	echo -e " CPU Flags            : ${SKYBLUE}AES-NI $aes & ${YELLOW}VM-x/AMD-V $virt ${PLAIN}" | tee -a $log
	echo -e " OS                   : ${SKYBLUE}$opsy ($lbit Bit) ${YELLOW}$virtual${PLAIN}" | tee -a $log
	echo -e " Kernel               : ${SKYBLUE}$kern${PLAIN}" | tee -a $log
	echo -e " Total Space          : ${SKYBLUE}$disk_used_size GB / ${YELLOW}$disk_total_size GB ${PLAIN}" | tee -a $log
	echo -e " Total RAM            : ${SKYBLUE}$uram MB / ${YELLOW}$tram MB ${SKYBLUE}($bram MB Buff)${PLAIN}" | tee -a $log
	echo -e " Total SWAP           : ${SKYBLUE}$uswap MB / $swap MB${PLAIN}" | tee -a $log
	echo -e " Uptime               : ${SKYBLUE}$up${PLAIN}" | tee -a $log
	echo -e " Load Average         : ${SKYBLUE}$load${PLAIN}" | tee -a $log
	echo -e " TCP CC               : ${SKYBLUE}$tcpctrl + ${YELLOW}$qdisc${PLAIN}" | tee -a $log
}

print_end_time() {
	end=$(date +%s) 
	time=$(( $end - $start ))
	if [[ $time -gt 60 ]]; then
		min=$(expr $time / 60)
		sec=$(expr $time % 60)
		echo -ne " Finished in  : ${min} min ${sec} sec" | tee -a $log
	else
		echo -ne " Finished in  : ${time} sec" | tee -a $log
	fi

	printf '\n' | tee -a $log

	bj_time=$(curl -s http://cgi.im.qq.com/cgi-bin/cgi_svrtime)

	if [[ $(echo $bj_time | grep "html") ]]; then
		bj_time=$(date -u +%Y-%m-%d" "%H:%M:%S -d '+8 hours')
	fi
	echo " Timestamp    : $bj_time GMT+8" | tee -a $log
	echo " Results      : $log"
}

get_system_info() {
	cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
	cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
	freq=$( awk -F: '/cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
	corescache=$( awk -F: '/cache size/ {cache=$2} END {print cache}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
	aes=$(cat /proc/cpuinfo | grep aes)
	[[ -z "$aes" ]] && aes="Disabled" || aes="Enabled"
	virt=$(cat /proc/cpuinfo | grep 'vmx\|svm')
	[[ -z "$virt" ]] && virt="Disabled" || virt="Enabled"
	tram=$( free -m | awk '/Mem/ {print $2}' )
	uram=$( free -m | awk '/Mem/ {print $3}' )
	bram=$( free -m | awk '/Mem/ {print $6}' )
	swap=$( free -m | awk '/Swap/ {print $2}' )
	uswap=$( free -m | awk '/Swap/ {print $3}' )
	up=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d days %d hour %d min\n",a,b,c)}' /proc/uptime )
	load=$( w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
	opsy=$( get_opsy )
	arch=$( uname -m )
	lbit=$( getconf LONG_BIT )
	kern=$( uname -r )

	disk_size1=$( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|overlay|shm|udev|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $2}' )
	disk_size2=$( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|overlay|shm|udev|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $3}' )
	disk_total_size=$( calc_disk ${disk_size1[@]} )
	disk_used_size=$( calc_disk ${disk_size2[@]} )

	tcpctrl=$( sysctl net.ipv4.tcp_congestion_control | awk -F ' ' '{print $3}' )
	qdisc=$(sysctl -n net.core.default_qdisc)

	virt_check
}

besttrace_test() {
    if [ "$2" = "tcp" ] || [ "$2" = "TCP" ]; then
        echo -e "\nTraceroute to $4 (TCP Mode, Max $3 Hop)" | tee -a $log
        echo -e "============================================================" | tee -a $log
        nexttrace -g cn -q 1 -n -T -m $3 $1 | tee -a $log
    else
        echo -e "\nTracecroute to $4 (ICMP Mode, Max $3 Hop)" | tee -a $log
        echo -e "============================================================" | tee -a $log
        nexttrace -g cn -q 1 -n -m $3 $1 | tee -a $log
    fi
}

print_besttrace_test(){
#	besttrace_test "113.108.209.1" "TCP" "30" "China, Guangzhou CT"
#	besttrace_test "180.153.28.5" "TCP" "30" "China, Shanghai CT"
#	besttrace_test "180.149.128.9" "TCP" "30" "China, Beijing CT"
#	besttrace_test "210.21.4.130" "TCP" "30" "China, Guangzhou CU"
#	besttrace_test "58.247.8.158" "TCP" "30" "China, Shanghai CU"
#	besttrace_test "123.125.99.1" "TCP" "30" "China, Beijing CU"
#	besttrace_test "120.196.212.25" "TCP" "30" "China, Guangzhou CM"
#	besttrace_test "221.183.55.22" "TCP" "30" "China, Shanghai CM"
#	besttrace_test "211.136.25.153" "TCP" "30" "China, Beijing CM"
#	besttrace_test "211.167.230.100" "TCP"  "30" "China, Beijing Dr.Peng Network IDC Network"
	besttrace_test "ipv4.sha-4134.endpoint.nxtrace.org" "TCP" "30" "上海电信"
	besttrace_test "ipv4.can-4134.endpoint.nxtrace.org" "TCP" "30" "广州电信"
	besttrace_test "ipv4.sha-4809.endpoint.nxtrace.org" "TCP" "30" "上海CN2"
	besttrace_test "ipv4.sha-4837.endpoint.nxtrace.org" "TCP" "30" "上海联通"
	besttrace_test "ipv4.can-4837.endpoint.nxtrace.org" "TCP" "30" "广州联通"
	besttrace_test "ipv4.sha-9929.endpoint.nxtrace.org" "TCP" "30" "上海联通9929"
	besttrace_test "ipv4.sha-9808.endpoint.nxtrace.org" "TCP" "30" "上海移动"
	besttrace_test "ipv4.can-9808.endpoint.nxtrace.org" "TCP" "30" "广州移动"
	besttrace_test "ipv4.hgh-4538.endpoint.nxtrace.org" "TCP" "30" "杭州教育网"
	besttrace_test "ipv6.sha-4134.endpoint.nxtrace.org" "ICMP" "30" "上海电信"
	besttrace_test "ipv6.sha-4837.endpoint.nxtrace.org" "ICMP" "30" "上海联通"
	besttrace_test "ipv6.sha-9929.endpoint.nxtrace.org" "ICMP" "30" "上海9929"
	besttrace_test "ipv6.sha-9808.endpoint.nxtrace.org" "ICMP" "30" "上海移动"
	besttrace_test "ipv6.can-9808.endpoint.nxtrace.org" "ICMP" "30" "广州移动"
	besttrace_test "ipv6.hgh-4538.endpoint.nxtrace.org" "ICMP" "30" "杭州教育网"
#	besttrace_test "101.4.117.213" "TCP" "30" "北京教育网"
#	echo "1" | nexttrace -F | tee -a $log
#	echo -e "2\n1" | nexttrace -F | tee -a $log
}

geekbench() {
	echo -e " Geekbench v${GeekbenchVer} Test    :" | tee -a $log
	if test -f "geekbench.license"; then
		./geekbench/geekbench$GeekbenchVer --unlock `cat geekbench.license` > /dev/null 2>&1
	fi
	
	GEEKBENCH_TEST=$(./geekbench/geekbench$GeekbenchVer --upload 2>/dev/null | grep "https://browser")
	
	if [[ -z "$GEEKBENCH_TEST" ]]; then
		echo -e " ${RED}Geekbench v${GeekbenchVer} test failed. Run manually to determine cause.${PLAIN}" | tee -a $log
		GEEKBENCH_URL=''
		if [[ $GeekbenchVer == *5* && $ARCH != *aarch64* && $ARCH != *arm* ]]; then
			rm -rf geekbench
			download_geekbench4;
			echo -n -e "\r" | tee -a $log
			GeekbenchVer=4;
			geekbench;
		fi
	else
		GEEKBENCH_URL=$(echo -e $GEEKBENCH_TEST | head -1)
		GEEKBENCH_URL_CLAIM=$(echo $GEEKBENCH_URL | awk '{ print $2 }')
		GEEKBENCH_URL=$(echo $GEEKBENCH_URL | awk '{ print $1 }')
		sleep 20
		[[ $GeekbenchVer == *5* ]] && GEEKBENCH_SCORES=$(curl -s $GEEKBENCH_URL | grep "div class='score'") || GEEKBENCH_SCORES=$(curl -s $GEEKBENCH_URL | grep "span class='score'")
		GEEKBENCH_SCORES_SINGLE=$(echo $GEEKBENCH_SCORES | awk -v FS="(>|<)" '{ print $3 }')
		GEEKBENCH_SCORES_MULTI=$(echo $GEEKBENCH_SCORES | awk -v FS="(>|<)" '{ print $7 }')
		
		echo -e "       Single Core    : ${YELLOW}$GEEKBENCH_SCORES_SINGLE  $grank${PLAIN}"  | tee -a $log
		echo -e "        Multi Core    : ${YELLOW}$GEEKBENCH_SCORES_MULTI${PLAIN}" | tee -a $log
		[ ! -z "$GEEKBENCH_URL_CLAIM" ] && echo -e "$GEEKBENCH_URL_CLAIM" >> geekbench_claim.url 2> /dev/null
	fi
	rm -rf geekbench
}

UnlockNetflixTest() {
    local result region
    result=$(curl -fsL -A "$userAgent" -m 10 -w "%{http_code}" -o /dev/null "https://www.netflix.com/title/81280792" 2>&1)

    if [[ "$result" == "404" ]]; then
        echo "Netflix               : $(_yellow 'Originals Only')" | tee -a "$log"
    elif  [[ "$result" == "403" ]]; then
        echo "Netflix               : $(_red 'No')" | tee -a "$log"
    elif [[ "$result" == "200" ]]; then
        region=$(curl -fs -A "$userAgent" -m 10 -w "%{redirect_url}" -o /dev/null "https://www.netflix.com/title/80018499" | cut -d '/' -f4 | awk -F'-' '{print toupper($1)}')
        region="${region:-US}"
        echo "Netflix               : $(_green "Yes (Region: $region)")" | tee -a "$log"
    elif  [[ "$result" == "000" ]]; then
        echo "Netflix               : $(_red 'Network connection failed')" | tee -a "$log"
    fi
}

function UnlockYouTubePremiumTest() {
    local tmpresult=$(curl -sS -H "Accept-Language: en" "https://www.youtube.com/premium" 2>&1 )
    local region=$(curl --user-agent "${userAgent}" -sL --max-time 10 "https://www.youtube.com/premium" | grep "countryCode" | sed 's/.*"countryCode"//' | cut -f2 -d'"')
	if [ -n "$region" ]; then
        sleep 0
	else
		isCN=$(echo $tmpresult | grep 'www.google.cn')
		if [ -n "$isCN" ]; then
			region=CN
		else	
			region=US
		fi	
	fi	
	
    if [[ "$tmpresult" == "curl"* ]];then
        echo -e " YouTube Premium      : ${RED}Network connection failed${PLAIN}"  | tee -a $log
        return;
    fi
    
    local result=$(echo $tmpresult | grep 'Premium is not available in your country')
    if [ -n "$result" ]; then
        echo -e " YouTube Premium      : ${RED}No${PLAIN} ${PLAIN}${GREEN} (Region: $region)${PLAIN}" | tee -a $log
        return;
		
    fi
    local result=$(echo $tmpresult | grep 'YouTube and YouTube Music ad-free')
    if [ -n "$result" ]; then
        echo -e " YouTube Premium      : ${GREEN}Yes (Region: $region)${PLAIN}" | tee -a $log
        return;
	else
		echo -e " YouTube Premium      : ${RED}Failed${PLAIN}" | tee -a $log
    fi
}

function YouTubeCDNTest() {
	local tmpresult=$(curl -sS --max-time 10 https://redirector.googlevideo.com/report_mapping 2>&1)    
    if [[ "$tmpresult" == "curl"* ]];then
        echo -e " YouTube Region       : ${RED}Network connection failed${PLAIN}" | tee -a $log
        return;
    fi
	iata=$(echo $tmpresult | grep router | cut -f2 -d'"' | cut -f2 -d"." | sed 's/.\{2\}$//' | tr [:lower:] [:upper:])
	checkfailed=$(echo $tmpresult | grep "=>")
	if [ -z "$iata" ] && [ -n "$checkfailed" ];then
		CDN_ISP=$(echo $checkfailed | awk '{print $3}' | cut -f1 -d"-" | tr [:lower:] [:upper:])
		echo -e " YouTube CDN          : ${YELLOW}Associated with $CDN_ISP${PLAIN}" | tee -a $log
		return;
	elif [ -n "$iata" ];then
		curl $useNIC -s --max-time 10 "https://www.iata.org/AirportCodesSearch/Search?currentBlock=314384&currentPage=12572&airport.search=${iata}" > ~/iata.txt
		local line=$(cat ~/iata.txt | grep -n "<td>"$iata | awk '{print $1}' | cut -f1 -d":")
		local nline=$(expr $line - 2)
		local location=$(cat ~/iata.txt | awk NR==${nline} | sed 's/.*<td>//' | cut -f1 -d"<")
		echo -e " YouTube CDN          : ${GREEN}$location${PLAIN}" | tee -a $log
		rm ~/iata.txt
		return;
	else
		echo -e " YouTube CDN          : ${RED}Undetectable${PLAIN}" | tee -a $log
		rm ~/iata.txt
		return;
	fi
	
}

function UnlockBilibiliTest() {
	#Test Mainland
    local randsession="$(cat /dev/urandom | head -n 32 | md5sum | head -c 32)";
    local result=$(curl --user-agent "${userAgent}" -fsSL --max-time 10 "https://api.bilibili.com/pgc/player/web/playurl?avid=82846771&qn=0&type=&otype=json&ep_id=307247&fourk=1&fnver=0&fnval=16&session=${randsession}&module=bangumi" 2>&1);
	if [[ "$result" != "curl"* ]]; then
        result="$(echo "${result}" | grep '"code"' | awk -F 'code":' '{print $2}' | awk -F ',' '{print $1}')";
        if [ "${result}" = "0" ]; then
            echo -e " BiliBili China       : ${GREEN}Yes (Region: Mainland Only)${PLAIN}" | tee -a $log
			return;
        fi
    else
        echo -e " BiliBili China       : ${RED}Network connection failed${PLAIN}" | tee -a $log
		return;
    fi
	
	#Test Hongkong/Macau/Taiwan
	randsession="$(cat /dev/urandom | head -n 32 | md5sum | head -c 32)";
	result=$(curl --user-agent "${userAgent}" -fsSL --max-time 10 "https://api.bilibili.com/pgc/player/web/playurl?avid=18281381&cid=29892777&qn=0&type=&otype=json&ep_id=183799&fourk=1&fnver=0&fnval=16&session=${randsession}&module=bangumi" 2>&1);
    if [[ "$result" != "curl"* ]]; then
        result="$(echo "${result}" | grep '"code"' | awk -F 'code":' '{print $2}' | awk -F ',' '{print $1}')";
        if [ "${result}" = "0" ]; then
            echo -e " BiliBili China       : ${GREEN}Yes (Region: HongKong/Macau/Taiwan Only)${PLAIN}" | tee -a $log
			return;
        fi
    else
        echo -e " BiliBili China       : ${RED}Network connection failed${PLAIN}" | tee -a $log
		return;
    fi
	
	#Test Taiwan
	randsession="$(cat /dev/urandom | head -n 32 | md5sum | head -c 32)";
	result=$(curl --user-agent "${userAgent}" -fsSL --max-time 10 "https://api.bilibili.com/pgc/player/web/playurl?avid=50762638&cid=100279344&qn=0&type=&otype=json&ep_id=268176&fourk=1&fnver=0&fnval=16&session=${randsession}&module=bangumi" 2>&1);
	if [[ "$result" != "curl"* ]]; then
		result="$(echo "${result}" | grep '"code"' | awk -F 'code":' '{print $2}' | awk -F ',' '{print $1}')";
		if [ "${result}" = "0" ]; then
            echo -e " BiliBili China       : ${GREEN}Yes (Region: Taiwan Only)${PLAIN}" | tee -a $log
			return;
		fi
	else
		echo -e " BiliBili China       : ${RED}Network connection failed${PLAIN}" | tee -a $log
		return;
	fi
	echo -e " BiliBili China       : ${RED}No${PLAIN}" | tee -a $log
}

function UnlockTiktokTest() {
#	echo -n -e " Tiktok Region:\t\t\c"
    local Ftmpresult=$(curl $useNIC --user-agent "${UA_Browser}" -s --max-time 10 "https://www.tiktok.com/")

    if [[ "$Ftmpresult" = "curl"* ]]; then
        echo -e " TikTok               : ${RED}No${PLAIN}" | tee -a $log
        return
    fi

    local FRegion=$(echo $Ftmpresult | grep '"region":' | sed 's/.*"region"//' | cut -f2 -d'"')
    if [ -n "$FRegion" ]; then
        echo -e " TikTok               : ${GREEN}Yes (Region: ${FRegion})${PLAIN}" | tee -a $log
        return
    fi

    local STmpresult=$(curl $useNIC --user-agent "${UA_Browser}" -sL --max-time 10 -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9" -H "Accept-Encoding: gzip" -H "Accept-Language: en" "https://www.tiktok.com" | gunzip 2>/dev/null)
    local SRegion=$(echo $STmpresult | grep '"region":' | sed 's/.*"region"//' | cut -f2 -d'"')
    if [ -n "$SRegion" ]; then
        echo -e " TikTok               : ${YELLOW}${SRegion}(可能为IDC IP)${PLAIN}" | tee -a $log
        return
    else
        echo -e " TikTok               : ${RED}Failed${PLAIN}" | tee -a $log
        return
    fi

}

function UnlockiQiyiIntlTest() {
	curl --user-agent "${userAgent}" -s -I --max-time 10 "https://www.iq.com/" >/tmp/iqiyi
    if [ $? -eq 1 ]; then
        echo -e " iQIYI International  : ${RED}Network connection failed${PLAIN}" | tee -a $log
        return
    fi

    local result="$(cat /tmp/iqiyi | grep 'mod=' | awk '{print $2}' | cut -f2 -d'=' | cut -f1 -d';')";
	rm -f /tmp/iqiyi

    if [ -n "$result" ]; then
        if [[ "$result" == "ntw" ]]; then
            result=TW
            echo -e " iQIYI International  : ${GREEN}Yes (Region: ${result})${PLAIN}" | tee -a $log
            return
        else
            result=$(echo $result | tr [:lower:] [:upper:])
            echo -e " iQIYI International  : ${GREEN}Yes (Region: ${result})${PLAIN}" | tee -a $log
            return
        fi
    else
        echo -e " iQIYI International  : ${RED}Failed${PLAIN}" | tee -a $log
        return
    fi
}

function UnlockChatGPTTest() {
	if [[ $(curl --max-time 10 -sS https://chat.openai.com/ -I | grep "text/plain") != "" ]]
	then
        echo -e " ChatGPT              : ${RED}IP is BLOCKED${PLAIN}" | tee -a $log
        return
	fi
    local countryCode="$(curl --max-time 10 -sS https://chat.openai.com/cdn-cgi/trace | grep "loc=" | awk -F= '{print $2}')";
	if [ $? -eq 1 ]; then
        echo -e " ChatGPT              : ${RED}Network connection failed${PLAIN}" | tee -a $log
        return
    fi
	if [ -n "$countryCode" ]; then
        support_countryCodes=(T1 XX AL DZ AD AO AG AR AM AU AT AZ BS BD BB BE BZ BJ BT BA BW BR BG BF CV CA CL CO KM CR HR CY DK DJ DM DO EC SV EE FJ FI FR GA GM GE DE GH GR GD GT GN GW GY HT HN HU IS IN ID IQ IE IL IT JM JP JO KZ KE KI KW KG LV LB LS LR LI LT LU MG MW MY MV ML MT MH MR MU MX MC MN ME MA MZ MM NA NR NP NL NZ NI NE NG MK NO OM PK PW PA PG PE PH PL PT QA RO RW KN LC VC WS SM ST SN RS SC SL SG SK SI SB ZA ES LK SR SE CH TH TG TO TT TN TR TV UG AE US UY VU ZM BO BN CG CZ VA FM MD PS KR TW TZ TL GB)
		if [[ "${support_countryCodes[@]}"  =~ "${countryCode}" ]];  then
            echo -e " ChatGPT              : ${GREEN}Yes (Region: ${countryCode})${PLAIN}" | tee -a $log
            return
        else
			echo -e " ChatGPT              : ${RED}No${PLAIN}" | tee -a $log
            return
        fi
    else
        echo -e " ChatGPT              : ${RED}Failed${PLAIN}" | tee -a $log
        return
    fi
}


function StreamingMediaUnlockTest(){
	echo -e " Stream Media Unlock  :" | tee -a $log
	UnlockNetflixTest
	UnlockYouTubePremiumTest
	YouTubeCDNTest
	UnlockBilibiliTest
	UnlockTiktokTest
	UnlockiQiyiIntlTest
	UnlockChatGPTTest
}

print_intro() {
	printf ' Superbench.sh -- https://vpsxb.net/448\n' | tee -a $log
	printf " Mode  : ${GREEN}%s${PLAIN}    Version : ${GREEN}%s${PLAIN}\n" $mode_name 1.3.0 | tee -a $log
	printf ' Usage : wget -qO- https://down.vpsxb.net/superbench/superbench.sh | bash\n' | tee -a $log
}

sharetest() {
	echo " Share result:" | tee -a $log
	echo " · $GEEKBENCH_URL" | tee -a $log
	echo " · $result_speed" | tee -a $log
	log_preupload
	case $1 in
	'ubuntu')
		share_link="https://paste.ubuntu.com"$( curl -v --data-urlencode "content@$log_up" -d "poster=superbench.sh" -d "syntax=text" "https://paste.ubuntu.com" 2>&1 | \
			grep "Location" | awk '{print $3}' );;
	'haste' )
		share_link=$( curl -X POST -s -d "$(cat $log)" https://hastebin.com/documents | awk -F '"' '{print "https://hastebin.com/"$4}' );;
	'clbin' )
		share_link=$( curl -sF 'clbin=<-' https://clbin.com < $log );;
	'ptpb' )
		share_link=$( curl -sF c=@- https://ptpb.pw/?u=1 < $log );;
	esac

	echo " · $share_link" | tee -a $log
	next
	echo ""
	rm -f $log_up

}

log_preupload() {
	log_up="$HOME/superbench_upload.log"
	true > $log_up
	$(cat superbench.log 2>&1 | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" > $log_up)
}

cleanup() {
	rm -f test_file_*
	rm -rf speedtest*
	rm -rf besttrace4*
	rm -rf geekbench*
}

bench_all(){
	mode_name="Standard"
	about;
	benchInit;
	clear
	next;
	print_intro;
	next;
	get_system_info;
	print_system_info;
	ip_info4;
	next;
	StreamingMediaUnlockTest;
	next;
	print_io;
	if [[ "$GeekbenchTest" == "Y" ]]; then
		next;
		geekbench;
	fi
	next;
	print_china_speedtest;
	next;
	print_global_speedtest;
	next;
	print_besttrace_test;
	next;
	print_end_time;
	next;
	cleanup;
	sharetest ubuntu;
}

fast_bench(){
	mode_name="Fast"
	about;
	benchInit;
	clear
	next;
	print_intro;
	next;
	get_system_info;
	print_system_info;
	ip_info4;
	next;
	StreamingMediaUnlockTest;
	next;
	print_io fast;
	next;
	print_speedtest_fast;
	next;
	print_besttrace_test;
	next;
	print_end_time;
	next;
	cleanup;
	sharetest ubuntu;
}

case $1 in
	'info'|'-i'|'--i'|'-info'|'--info' )
		GeekbenchTest='N';
		about;sleep 3;next;get_system_info;print_system_info;next;;
    'version'|'-v'|'--v'|'-version'|'--version')
		GeekbenchTest='N';
		next;about;next;;
   	'io'|'-io'|'--io'|'-drivespeed'|'--drivespeed' )
		next;print_io;next;;
	'speed'|'-speed'|'--speed'|'-speedtest'|'--speedtest'|'-speedcheck'|'--speedcheck' )
		GeekbenchTest='N';
		about;benchInit;clear;next;print_china_speedtest;next;cleanup;;
	'ip'|'-ip'|'--ip'|'geoip'|'-geoip'|'--geoip' )
		about;benchInit;next;ip_info4;next;cleanup;;
	'bench'|'-a'|'--a'|'-all'|'--all'|'-bench'|'--bench' )
		bench_all;;
	'besttrace'|'-b'|'--b'|'--besttrace' )
		GeekbenchTest='N';
		print_besttrace_test;;
	'about'|'-about'|'--about' )
		GeekbenchTest='N';
		about;;
	'fast'|'-f'|'--f'|'-fast'|'--fast' )
		fast_bench;;
	'geekbench'|'-g'|'--geekbench' )
		geekbench;;
	'--no-geekbench' )
		GeekbenchTest='N';
		bench_all;;
	'media'|'-m'|'--media' )
		GeekbenchTest='N';
		StreamingMediaUnlockTest;;
	'share'|'-s'|'--s'|'-share'|'--share' )
		bench_all;
		is_share="share"
		if [[ $2 == "" ]]; then
			sharetest ubuntu;
		else
			sharetest $2;
		fi
		;;
	'debug'|'-d'|'--d'|'-debug'|'--debug' )
		get_ip_whois_org_name;;
*)
    bench_all;;
esac

if [[  ! $is_share == "share" ]]; then
	case $2 in
		'share'|'-s'|'--s'|'-share'|'--share' )
			if [[ $3 == '' ]]; then
				sharetest ubuntu;
			else
				sharetest $3;
			fi
			;;
	esac
fi
