#!/usr/bin/env bash

yellow='\033[93m'
red='\033[0;31m'
green='\033[92m'
blue='\033[36m'
white='\033[0m'
_yellow() { echo -e "${yellow}$*${white}"; }
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }
_blue() { echo -e "${blue}$*${white}"; }

_err_msg() { echo -e "\033[41m\033[1mwarn${white} $*"; }
_suc_msg() { echo -e "\033[42m\033[1msuccess${white} $*"; }

temp_Dir='/tmp/bench'

separator() { printf "%-70s\n" "-" | sed 's/\s/-/g'; }

_exit() {
    separator
    rm -rf "$temp_Dir"
    exit 0
}

trap "_exit" SIGINT SIGQUIT SIGTERM EXIT

mkdir -p "$temp_Dir"

install_speedtest() {
    local speedtest_ver sys_arch

    speedtest_ver="1.7.9"
    speedtest_dir="$temp_Dir/speedtest" # 被调用后全局变量
    mkdir -p "$speedtest_dir"

    case "$(uname -m)" in
        'i386' | 'i686' )
            sys_arch="i386"
        ;;
        'x86_64' )
            sys_arch="x86_64"
        ;;
        'armv6')
            sys_arch="armv6"
        ;;
        'armv7' | 'armv7l' )
            sys_arch="armv7"
        ;;
        'armv8' | 'armv8l' | 'aarch64' | 'arm64' )
            sys_arch="arm64"
        ;;
        *)
            _err_msg "$(_red "Error: Unsupported system architecture (${sys_arch})")" && exit 1
        ;;
    esac

    if ! curl -fskL -o "$speedtest_dir/speedtest.tar.gz" "https://github.com/showwin/speedtest-go/releases/download/v${speedtest_ver}/speedtest-go_${speedtest_ver}_Linux_${sys_arch}.tar.gz"; then
        _err_msg "$(_red 'Error: Failed to download speedtest-go')" && exit 1
    fi

    tar zxf "$speedtest_dir/speedtest.tar.gz" -C "$speedtest_dir"

    printf "%-18s%-18s%-20s%-12s\n" " Node Name" "Upload Speed" "Download Speed" "Latency"
}

# https://github.com/showwin/speedtest-go
speed_test() {
    local upload_speed download_speed latency
    local nodeName="$2"

    if [ -z "$1" ]; then
        "$speedtest_dir/speedtest-go" --unix > "$speedtest_dir/speedtest.log" 2>&1 || return
    else
        "$speedtest_dir/speedtest-go" --unix -s "$1" > "$speedtest_dir/speedtest.log" 2>&1 || return
    fi

    upload_speed=$(awk -F': ' '/Upload/ {split($2, a, " "); print a[1] " " a[2]; exit}' "$speedtest_dir/speedtest.log")
    download_speed=$(awk -F': ' '/Download/ {split($2, a, " "); print a[1] " " a[2]; exit}' "$speedtest_dir/speedtest.log")
    latency=$(awk '/Latency:/ {sub(/ms$/, "", $2); printf "%.2fms", $2; exit}' "$speedtest_dir/speedtest.log")

    if [ -n "$download_speed" ] && [ -n "$upload_speed" ] && [ -n "$latency" ]; then
        printf "${yellow}%-18s${green}%-18s${red}%-20s${blue}%-12s${white}\n" " $nodeName" "$upload_speed" "$download_speed" "$latency"
    fi
}

speed() {
    speed_test '' 'Speedtest.net'
    speed_test '65463' 'Hong Kong, HK'
    speed_test '50406' 'Singapore, SG'
    speed_test '62217' 'Tokyo, JP'
    speed_test '67564' 'Seoul, KR'
    speed_test '13516' 'Los Angeles, US'
    speed_test '31120' 'Frankfurt, DE'
    speed_test '57725' 'Warsaw, PL'
    speed_test '54312' 'Zhejiang, CN'
    speed_test '5396' 'JiangSu, CN'
}

install_speedtest
speed