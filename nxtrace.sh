#!/usr/bin/env bash
#
# Description: This script installs or updates the latest NextTrace version, overcoming the official script's restriction to only stable versions.
#
# Copyright (c) 2025 honeok <i@honeok.com>
# Modified from the project: https://github.com/nxtrace/NTrace-V1
#
# References:
# https://github.com/bin456789/reinstall
#
# This script utilizes NextTrace, a powerful network diagnostic tool.
# NextTrace is copyrighted and developed by the NextTrace project team.
# For more details about NextTrace, visit: https://github.com/nxtrace
#
# SPDX-License-Identifier: GPL-3.0

_red() { printf "\033[31m%b\033[0m\n" "$*"; }
_err_msg() { printf "\033[41m\033[1mError\033[0m %b\n" "$*"; }
_suc_msg() { printf "\033[42m\033[1mSuccess\033[0m %b\n" "$*"; }
_info_msg() { printf "\033[43m\033[1mInfo\033[0m %b\n" "$*"; }

# 各变量默认值
TEMP_DIR="$(mktemp -d)"
GITHUB_PROXY='https://gh-proxy.com/'

trap 'rm -rf "${TEMP_DIR:?}" >/dev/null 2>&1' INT TERM EXIT

# 打印错误信息并退出
die() {
    _err_msg >&2 "$(_red "$@")"; exit 1
}

curl() {
    local RET
    # 添加 --fail 不然404退出码也为0
    # 32位Cygwin已停止更新, 证书可能有问题, 添加 --insecure
    # Centos7 curl 不支持 --retry-connrefused --retry-all-errors 因此手动 retry
    for i in {1..5}; do
        command curl --insecure --connect-timeout 10 --fail "$@"
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

# 临时工作目录
cd "$TEMP_DIR" >/dev/null 2>&1 || die "无法进入工作路径"

clrScr() {
    [ -t 1 ] && tput clear 2>/dev/null || echo -e "\033[2J\033[H" || clear
}

check_root() {
    [ "$EUID" -ne 0 ] || [ "$(id -ru)" -ne 0 ] && die "此脚本必须以root身份运行"
}

check_cdn() {
    [[ -n "$GITHUB_PROXY" && "$(curl -Ls http://www.qualcomm.cn/cdn-cgi/trace | grep '^loc=' | cut -d= -f2 | grep .)" != "CN" ]] && unset GITHUB_PROXY
}

check_sys() {
    case "$(uname -s | awk '{print tolower($0)}')" in
        linux) SYSTEM="linux" ;;
        *) die "系统不被支持" ;;
    esac
}

check_arch() {
    case "$(uname -m)" in
        i386|i686) ARCH="386" ;;
        x86_64) ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        armv7l*) ARCH="armv7" ;;
        mips) ARCH="mips" ;;
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
    local NTRACE_VERSION

    _info_msg "获取最新NextTrace发行版文件信息"

    NTRACE_VERSION="$(curl -Ls https://api.github.com/repos/nxtrace/NTrace-V1/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
    [ -n "$NTRACE_VERSION" ] || die "获取版本信息失败, 请检查您的网络是否正常"

    if ! curl -Lso nexttrace "${GITHUB_PROXY}https://github.com/nxtrace/NTrace-V1/releases/download/${NTRACE_VERSION}/nexttrace_${SYSTEM}_${ARCH}"; then
        die "NextTrace下载失败, 请检查您的网络是否正常"
    fi

    [ ! -x nexttrace ] && chmod +x nexttrace
    mv -f nexttrace "$BIN_WORKDIR"

    _suc_msg "NextTrace现在已经在您的系统中可用"
}

ntrace_info() {
    if [ -e "$BIN_WORKDIR" ]; then
        "$BIN_WORKDIR" --version
        _suc_msg "一切准备就绪! 使用命令 nexttrace 1.1.1.1 开始您的第一次路由测试吧, 更多进阶命令玩法可以用 nexttrace -h 查看"
        echo "关于软件卸载, 因为nexttrace是绿色版单文件, 卸载只需输入命令 rm $BIN_WORKDIR 即可"
    fi
}

clrScr
check_root
check_cdn
check_sys
check_arch
work_dir
ntrace_down
ntrace_info