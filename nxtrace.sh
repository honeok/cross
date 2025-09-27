#!/usr/bin/env bash
#
# Description: This script installs or updates the latest nexttrace version, overcoming the official script's restriction to only stable versions.
# Modified from the project: https://github.com/nxtrace/NTrace-V1
#
# Copyright (c) 2025 honeok <i@honeok.com>
# SPDX-License-Identifier: GPL-3.0
#
# References:
# https://github.com/bin456789/reinstall
#
# This script utilizes NextTrace, a powerful network diagnostic tool.
# NextTrace is copyrighted and developed by the NextTrace project team.
# For more details about NextTrace, visit: https://github.com/nxtrace

set -eE

_red() { printf "\033[31m%b\033[0m\n" "$*"; }
_green() { printf "\033[92m%b\033[0m\n" "$*"; }
_yellow() { printf "\033[93m%b\033[0m\n" "$*"; }
_err_msg() { printf "\033[41m\033[1mError\033[0m %b\n" "$*"; }
_suc_msg() { printf "\033[42m\033[1mSuccess\033[0m %b\n" "$*"; }
_info_msg() { printf "\033[43m\033[1mInfo\033[0m %b\n" "$*"; }

# 各变量默认值
TEMP_DIR="$(mktemp -d)"
GITHUB_PROXY='https://gh-proxy.com/'

trap 'rm -rf "${TEMP_DIR:?}" >/dev/null 2>&1' INT TERM EXIT

clear() {
    [ -t 1 ] && tput clear 2>/dev/null || printf "\033[2J\033[H" || command clear
}

# 打印错误信息并退出
die() {
    _err_msg >&2 "$(_red "$@")"; exit 1
}

# 临时工作目录
cd "$TEMP_DIR" >/dev/null 2>&1 || die "无法进入工作路径"

_exists() {
    local _CMD="$1"
    if type "$_CMD" >/dev/null 2>&1; then return;
    elif command -v "$_CMD" >/dev/null 2>&1; then return;
    elif which "$_CMD" >/dev/null 2>&1; then return;
    else return 1;
    fi
}

curl() {
    local RET
    # 添加 --fail 不然404退出码也为0
    # 32位cygwin已停止更新, 证书可能有问题, 添加 --insecure
    # centos7 curl 不支持 --retry-connrefused --retry-all-errors 因此手动 retry
    for ((i=1; i<=5; i++)); do
        command curl --connect-timeout 10 --fail --insecure "$@"
        RET=$?
        if [ "$RET" -eq 0 ]; then
            return
        else
            # 403 404 错误或达到重试次数
            if [ "$RET" -eq 22 ] || [ "$i" -eq 5 ]; then
                return "$RET"
            fi
            sleep 1
        fi
    done
}

check_root() {
    if [ "$EUID" -ne 0 ] || [ "$(id -ru)" -ne 0 ]; then
        die "此脚本必须以root身份运行"
    fi
}

check_cdn() {
    if [[ -n "$GITHUB_PROXY" && "$(curl -Ls http://www.qualcomm.cn/cdn-cgi/trace | grep '^loc=' | cut -d= -f2 | grep .)" != "CN" ]]; then
        unset GITHUB_PROXY
    fi
}

check_sys() {
    case "$(uname -s 2>/dev/null | sed 's/.*/\L&/')" in
        linux) OS_NAME="linux" ;;
        *) die "系统不被支持" ;;
    esac
}

check_arch() {
    case "$(uname -m 2>/dev/null)" in
        i*86) OS_ARCH="386" ;;
        amd64|x86_64) OS_ARCH="amd64" ;;
        arm64|armv8|aarch64) OS_ARCH="arm64" ;;
        armv7*) OS_ARCH="armv7" ;;
        mips) OS_ARCH="mips" ;;
        *) die "架构不被支持" ;;
    esac
}

work_dir() {
    if [ -w "/usr/local/bin" ]; then
        BIN_WORKDIR="/usr/local/bin/nexttrace"
    else
        BIN_WORKDIR="/usr/bin/nexttrace"
    fi
}

ntrace_down() {
    local NTRACE_VER

    _info_msg "$(_yellow "获取最新NextTrace发行版文件信息")"

    NTRACE_VER="$(curl -Ls "${GITHUB_PROXY}https://api.github.com/repos/nxtrace/NTrace-V1/releases" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sort -Vr | head -n1)"
    [ -n "$NTRACE_VER" ] || die "获取版本信息失败, 请检查您的网络是否正常"

    if ! curl -Ls "${GITHUB_PROXY}https://github.com/nxtrace/NTrace-V1/releases/download/$NTRACE_VER/nexttrace_${OS_NAME}_${OS_ARCH}" -o nexttrace; then
        die "NextTrace下载失败, 请检查您的网络是否正常"
    fi

    if [ ! -x ./nexttrace ]; then
        chmod +x ./nexttrace
    fi

    mv -f ./nexttrace "$BIN_WORKDIR"

    if _exists nexttrace; then
        _suc_msg "$(_green "NextTrace现在已经在您的系统中可用")"
    else
        die "NextTrace安装失败, 请重试"
    fi
}

ntrace_info() {
    if [ -e "$BIN_WORKDIR" ]; then
        "$BIN_WORKDIR" --version
        _suc_msg "一切准备就绪! 使用命令 nexttrace 1.1.1.1 开始您的第一次路由测试吧, 更多进阶命令玩法可以用 nexttrace -h 查看"
        echo "关于软件卸载, 因为nexttrace是绿色版单文件, 卸载只需输入命令 rm $BIN_WORKDIR 即可"
    fi
}

clear
check_root
check_cdn
check_sys
check_arch
work_dir
ntrace_down
ntrace_info
