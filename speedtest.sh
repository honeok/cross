#!/usr/bin/env bash

# shellcheck disable=all

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

# install_speedtest() {
#     if [ ! -e "./speedtest-cli/speedtest" ]; then
#         sys_bit=""
#         local sysarch
#         sysarch="$(uname -m)"
#         if [ "${sysarch}" = "unknown" ] || [ "${sysarch}" = "" ]; then
#             sysarch="$(arch)"
#         fi
#         if [ "${sysarch}" = "x86_64" ]; then
#             sys_bit="x86_64"
#         fi
#         if [ "${sysarch}" = "i386" ] || [ "${sysarch}" = "i686" ]; then
#             sys_bit="i386"
#         fi
#         if [ "${sysarch}" = "armv8" ] || [ "${sysarch}" = "armv8l" ] || [ "${sysarch}" = "aarch64" ] || [ "${sysarch}" = "arm64" ]; then
#             sys_bit="aarch64"
#         fi
#         if [ "${sysarch}" = "armv7" ] || [ "${sysarch}" = "armv7l" ]; then
#             sys_bit="armhf"
#         fi
#         if [ "${sysarch}" = "armv6" ]; then
#             sys_bit="armel"
#         fi
#         [ -z "${sys_bit}" ] && _red "Error: Unsupported system architecture (${sysarch}).\n" && exit 1
#         url1="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-${sys_bit}.tgz"
#         url2="https://dl.lamp.sh/files/ookla-speedtest-1.2.0-linux-${sys_bit}.tgz"
#         if ! wget --no-check-certificate -q -T10 -O speedtest.tgz ${url1}; then
#             if ! wget --no-check-certificate -q -T10 -O speedtest.tgz ${url2}; then
#                 _red "Error: Failed to download speedtest-cli.\n" && exit 1
#             fi
#         fi
#         mkdir -p speedtest-cli && tar zxf speedtest.tgz -C ./speedtest-cli && chmod +x ./speedtest-cli/speedtest
#         rm -f speedtest.tgz
#     fi
#     printf "%-18s%-18s%-20s%-12s\n" " Node Name" "Upload Speed" "Download Speed" "Latency"
# }

mkdir -p "$temp_Dir/speedtest"

# https://github.com/showwin/speedtest-go
speed_test() {
    local upload_speed download_speed latency
    local nodeName="$2"

    if [ -z "$1" ]; then
        ./speedtest-go --unix > "$temp_Dir/speedtest/speedtest.log" 2>&1 || return
    else
        ./speedtest-go --unix -s "$1" > "$temp_Dir/speedtest/speedtest.log" 2>&1 || return
    fi

    upload_speed=$(awk -F': ' '/Upload/ {split($2, a, " "); print a[1] " " a[2]; exit}' "$temp_Dir/speedtest/speedtest.log")
    download_speed=$(awk -F': ' '/Download/ {split($2, a, " "); print a[1] " " a[2]; exit}' "$temp_Dir/speedtest/speedtest.log")
    latency=$(awk '/Latency:/ {sub(/ms$/, "", $2); printf "%.2fms", $2; exit}' "$temp_Dir/speedtest/speedtest.log")

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

speed