#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0
#
# Based on from: https://github.com/nxtrace/NTrace-core
#                https://github.com/nxtrace/NTrace-V1
# Description: The script installs NextTrace with support for stable/dev channels, custom versions, and multi-architecture compatibility.
# Copyright (c) 2025-2026 honeok <i@honeok.com>

set -eE

# MAJOR.MINOR.PATCH
readonly SCRIPT_VERSION='v1.0.0'

_red() {
    printf "\033[31m%b\033[0m\n" "$*"
}

_green() {
    printf "\033[32m%b\033[0m\n" "$*"
}

_yellow() {
    printf "\033[33m%b\033[0m\n" "$*"
}

_cyan() {
    printf "\033[36m%b\033[0m\n" "$*"
}

_err_msg() {
    printf "\033[41m\033[1mError\033[0m %b\n" "$*"
}

_suc_msg() {
    printf "\033[42m\033[1mSuccess\033[0m %b\n" "$*"
}

_warn_msg() {
    printf "\033[43m\033[1mWarning\033[0m %b\n" "$*"
}

# 斜体输出
_italic() {
    printf "\033[3m%b\033[23m\n" "$*"
}

# 各变量默认值
TEMP_DIR="$(mktemp -d)"
GITHUB_PROXY="${GITHUB_PROXY:-}"
GITHUB_PROXYS=('' 'https://v6.gh-proxy.org/' 'https://hub.glowp.xyz/' 'https://proxy.vvvv.ee/')

trap 'rm -rf "${TEMP_DIR:?}" > /dev/null 2>&1' INT TERM EXIT

VERSION="${VERSION#v}"

# 安装渠道来源:
#   * stable
#   * dev
DEFAULT_CHANNEL_VALUE="stable"
if [ -z "$CHANNEL" ]; then
    CHANNEL="$DEFAULT_CHANNEL_VALUE"
fi

clear() {
    [ -t 1 ] && tput clear 2> /dev/null || printf "\033[2J\033[H" || command clear
}

die() {
    _err_msg >&2 "$(_red "$@")"
    exit 1
}

usage_and_exit() {
    _italic "$(_cyan "Script Version: $SCRIPT_VERSION")"
    tee >&2 <<- 'EOF'
Usage: ./nxtrace.sh [Options]

Options:
    -h, --help          Show this help message and exit
    --channel <name>    Install from channel: stable (default) or dev
    --version <ver>     Install a specific version (e.g., 1.2.3)
    --debug             Enable debug mode (set -x)

Examples:
    # Install stable version
    ./nxtrace.sh

    # Install specific version from dev channel
    ./nxtrace.sh --channel dev --version <ver>
EOF
    exit 91
}

cd "$TEMP_DIR" > /dev/null 2>&1 || die "Can't access temporary work dir."

while [ "$#" -gt 0 ]; do
    case "$1" in
    -h | --help)
        usage_and_exit
        ;;
    --channel)
        CHANNEL="$2"
        shift
        ;;
    --debug)
        set -x
        ;;
    --version)
        VERSION="${2#v}"
        shift
        ;;
    --*)
        _yellow "Illegal option $1"
        ;;
    esac
    shift $(($# > 0 ? 1 : 0))
done

case "$CHANNEL" in
stable)
    DOWNLOAD_URL="https://github.com/nxtrace/NTrace-core"
    RELEASES_URL="https://api.github.com/repos/nxtrace/NTrace-core/releases"
    ;;
dev)
    DOWNLOAD_URL="https://github.com/nxtrace/NTrace-V1"
    RELEASES_URL="https://api.github.com/repos/nxtrace/NTrace-V1/releases"
    ;;
*)
    die "unknown CHANNEL $CHANNEL: use either stable or dev."
    ;;
esac

get_cmd_path() {
    # -f: 忽略shell内置命令和函数, 只考虑外部命令
    # -p: 只输出外部命令的完整路径
    type -f -p "$1"
}

is_have_cmd() {
    get_cmd_path "$1" > /dev/null 2>&1
}

curl() {
    local RET
    # 添加 --fail 不然404退出码也为0
    # 32位cygwin已停止更新, 证书可能有问题, 添加 --insecure
    # centos7 curl 不支持 --retry-connrefused --retry-all-errors 因此手动 retry
    for ((i = 1; i <= 5; i++)); do
        command curl --connect-timeout 10 --fail --insecure "$@"
        RET="$?"
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

is_ci() {
    if [ -n "$GITHUB_ACTIONS" ]; then
        return
    elif [ -n "$GITLAB_CI" ]; then
        return
    elif [ -n "$JENKINS_URL" ]; then
        return
    elif [ -n "$TEAMCITY_GIT_PATH" ]; then
        return
    else
        return 1
    fi
}

is_not_root() {
    [ "$(id -u)" -ne 0 ]
}

# 检测是否需要启用Github CDN如能直接连通则不使用
check_cdn() {
    # GITHUB_PROXYS数组第一个元素为空相当于直连
    local CHECK_URL STATUS_CODE

    if is_ci; then
        return
    fi

    for PROXY_URL in "${GITHUB_PROXYS[@]}"; do
        CHECK_URL="${PROXY_URL}${RELEASES_URL}"
        STATUS_CODE="$(command curl --connect-timeout 3 --fail --insecure -Ls --output /dev/null --write-out "%{http_code}" "$CHECK_URL")"
        [ "$STATUS_CODE" = "200" ] && GITHUB_PROXY="$PROXY_URL" && break
    done
}

is_darwin() {
    [ "$(uname -s 2> /dev/null)" = "Darwin" ]
}

is_linux() {
    [ "$(uname -s 2> /dev/null)" = "Linux" ]
}

is_writable() {
    [ -w "$1" ]
}

check_sys() {
    if is_linux; then
        OS_NAME="linux"
    elif is_darwin; then
        OS_NAME="darwin"
    else
        die "System is not supported."
    fi
}

check_arch() {
    if is_linux; then
        case "$(uname -m 2> /dev/null)" in
        i*86) OS_ARCH="386" ;;
        amd64 | x86_64) OS_ARCH="amd64" ;;
        arm64 | armv8 | aarch64) OS_ARCH="arm64" ;;
        armv7*) OS_ARCH="armv7" ;;
        mips) OS_ARCH="mips" ;;
        *) die "Architecture is not supported." ;;
        esac
    elif is_darwin; then
        case "$(uname -m 2> /dev/null)" in
        amd64 | x86_64) OS_ARCH="amd64" ;;
        arm64 | armv8 | aarch64) OS_ARCH="arm64" ;;
        *) die "Architecture is not supported." ;;
        esac
    else
        die "Architecture is not supported."
    fi
}

do_install() {
    local SH_C BIN_WORKDIR

    if is_have_cmd nexttrace; then
        tee >&2 <<- EOF
			$(_warn_msg "")The "nexttrace" command appears to already exist on this system.
        Press Ctrl +C to abort this script if you do not want to overwrite it.
		EOF
        (sleep 5)
    fi

    SH_C="${SH_C:-}"
    if is_not_root; then
        if is_have_cmd sudo; then
            SH_C="sudo"
        else
            die "This installer needs the ability to run commands as root."
        fi
    fi

    check_sys
    check_arch

    [ -n "$VERSION" ] || VERSION="$(curl -Ls "${GITHUB_PROXY}${RELEASES_URL}" | grep '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/' | head -n 1)"
    curl -L "${GITHUB_PROXY}${DOWNLOAD_URL}/releases/download/v${VERSION}/nexttrace_${OS_NAME}_${OS_ARCH}" -o nexttrace || die "NextTrace download failed."

    if is_writable "/usr/local/bin"; then
        BIN_WORKDIR="/usr/local/bin/nexttrace"
    else
        BIN_WORKDIR="/usr/bin/nexttrace"
    fi

    eval "$SH_C install -m 755 ./nexttrace $BIN_WORKDIR"

    if is_have_cmd nexttrace; then
        _suc_msg "$(_green "NextTrace is now available on your system.")"
        eval "$BIN_WORKDIR" --version
    else
        die "NextTrace installation failed, please try again"
    fi
}

clear
check_cdn
do_install
