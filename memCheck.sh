#!/usr/bin/env bash
#
# Description: Detects whether the server's memory is oversold.
#
# Original Project: https://github.com/uselibrary/memoryCheck
# Forked and Modified By: honeok <honeok@duck.com>
#
# https://www.honeok.com
# https://github.com/honeok/cross/raw/master/memoryCheck.sh
#
# shellcheck disable=SC2164

export LANG=en_US.UTF-8

yellow='\033[93m'
red='\033[31m'
green='\033[92m'
cyan='\033[36m'
white='\033[0m'
_yellow() { echo -e "${yellow}$*${white}"; }
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }
_cyan() { echo -e "${cyan}$*${white}"; }

_info_msg() { echo -e "\033[48;5;178m\033[1m\033[97m提示${white} $*"; }
_err_msg() { echo -e "\033[41m\033[1m警告${white} $*"; }
_suc_msg() { echo -e "\033[42m\033[1m成功${white} $*"; }

short_separator() { printf "%-20s\n" "-" | sed 's/\s/-/g'; }

clear

[ "$(id -u)" -ne "0" ] && _err_msg "$(_red '请使用root用户！')" && exit 1

if [ "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" != "/root" ]; then
    cd /root >/dev/null 2>&1
fi

_yellow "开始检测内存超售"

short_separator

# 检查是否使用了swap超售内存
_yellow "检查是否使用了swap超售内存"
memSize=$(free -m | awk '/Mem/ {print $2}')
memSpeed=$(dd if=/dev/zero of=/dev/null bs=1M count="$memSize" 2>&1 | awk 'END {print $(NF-1)}' | awk '{printf("%.0f\n", $1)}')
_cyan "内存IO速度: ${memSpeed} GB/s"
if [ "$memSpeed" -lt 10 ]; then
    _err_msg "$(_red '内存IO速度低于10 GB/s')"
    _info_msg "$(_red '可能存在swap超售内存')"
else
    _suc_msg "$(_green '内存IO速度正常')"
    _green "未使用swap超售内存"
fi

short_separator

# 检查是否使用了气球驱动Balloon超售内存
_yellow "检查是否使用了气球驱动Balloon超售内存"
if lsmod | grep virtio_balloon >/dev/null 2>&1; then
    _err_msg "$(_red '存在virtio_balloon模块')"
    _info_msg "$(_red '可能使用了气球驱动Balloon超售内存')"
else
    _suc_msg "$(_green '不存在virtio_balloon模块')"
    _green "未使用气球驱动Balloon超售内存"
fi

short_separator

# 检查是否使用了Kernel Samepage Merging (KSM) 超售内存
_yellow "检查是否使用了Kernel Samepage Merging(KSM)超售内存"
if [ "$(cat /sys/kernel/mm/ksm/run)" == 1 ]; then
    _err_msg "$(_red 'Kernel Samepage Merging状态为1')"
    _info_msg "$(_red '可能使用了Kernel Samepage Merging (KSM) 超售内存')"
else
    _suc_msg "$(_green 'Kernel Samepage Merging状态正常')"
    _green "未使用Kernel Samepage Merging (KSM) 超售内存"
fi