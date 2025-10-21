#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0
#
# Description: This script is used to automatically update xray-core and the latest geoip/geosite data.
# Copyright (c) 2025 honeok <i@honeok.com>

# References:
# https://github.com/233boy/Xray
# https://github.com/bin456789/reinstall
# Thanks:
# https://github.com/XTLS/Xray-core
# https://github.com/Loyalsoldier/v2ray-rules-dat

set -eEu

# 设置PATH环境变量
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH
# 环境变量用于在debian或ubuntu操作系统中设置非交互式 (noninteractive) 安装模式
export DEBIAN_FRONTEND=noninteractive

# 各变量默认值
GITHUB_PROXY="https://proxy.zzwsec.com/"
TEMP_DIR="$(mktemp -d)"
CORE_NAME="xray"
CORE_DIR="/etc/$CORE_NAME"
CORE_BIN="$CORE_DIR/bin/$CORE_NAME"
SCRIPT_DIR="$CORE_DIR/sh"
SCRIPT_BIN="/usr/local/bin/$CORE_NAME" # 软连接 /etc/xray/sh/xray.sh

# 终止信号捕获
trap 'rm -rf "${TEMP_DIR:?}" >/dev/null 2>&1' SIGINT SIGTERM EXIT

clear() {
    [ -t 1 ] && tput clear 2>/dev/null || printf "\033[2J\033[H" || command clear
}

die() {
    echo >&2 "Error: $*"; exit 1
}

# 临时工作目录
cd "$TEMP_DIR" >/dev/null 2>&1 || die "Unable to enter the work path."

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

# 生成随机字符
random_char() {
    local LENGTH="$1"

    RANDOM_STRING="$(LC_ALL=C tr -cd 'a-zA-Z0-9' </dev/urandom | fold -w "$LENGTH" | head -n1)"
    echo "$RANDOM_STRING"
}

pkg_install() {
    for pkg in "$@"; do
        if _exists dnf; then
            dnf install -y "$pkg"
        elif _exists yum; then
            yum install -y "$pkg"
        elif _exists apt-get; then
            apt-get update
            apt-get install -y -q "$pkg"
        elif _exists apk; then
            apk add --no-cache "$pkg"
        elif _exists pacman; then
            pacman -S --noconfirm --needed "$pkg"
        else
            die "The package manager is not supported."
        fi
    done
}

check_root() {
    if [ "$EUID" -ne 0 ] || [ "$(id -ru)" -ne 0 ]; then
        die "This script must be run as root."
    fi
}

check_bash() {
    local BASH_VER
    BASH_VER="$(bash --version 2>&1 | head -n1 | awk -F ' ' '{for (i=1; i<=NF; i++) if ($i ~ /^[0-9]+\.[0-9]+\.[0-9]+/) {print $i; exit}}' | cut -d . -f1)"

    if [ -z "$BASH_VERSION" ]; then
        die "This script needs to be run with bash, not sh!"
    fi
    if [ -z "$BASH_VER" ] || ! [[ "$BASH_VER" =~ ^[0-9]+$ ]]; then
        die "Failed to parse Bash version!"
    fi
    if [ "$BASH_VER" -lt 4 ]; then
        die "Bash version is lower than 4.0!"
    fi
}

check_cdn() {
    local COUNTRY

    COUNTRY="$(curl -Ls -4 http://www.qualcomm.cn/cdn-cgi/trace | grep '^loc=' | cut -d= -f2 || true)"
    if [[ -n "$GITHUB_PROXY" && -n "$COUNTRY" && "$COUNTRY" != "CN" ]]; then
        GITHUB_PROXY=""
    fi
}

# 安装必要的软件包
check_cmd() {
    local -a INSTALL_PKG
    INSTALL_PKG=("curl" "unzip")

    for pkg in "${INSTALL_PKG[@]}"; do
        if ! _exists "$pkg" >/dev/null 2>&1; then
            pkg_install "$pkg"
        fi
    done
}

# 更新xray内核
update_core() {
    local LATEST_VER CURRENT_VER OS_NAME OS_ARCH
    local -a CORE_FILES

    LATEST_VER="$(curl -Ls "${GITHUB_PROXY}https://api.github.com/repos/XTLS/Xray-core/releases" | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' | sort -rV | head -n1)"
    CURRENT_VER="$("$CORE_BIN" version 2>/dev/null | head -n1 | sed -n 's/^Xray \([0-9.]\+\).*/\1/p')"
    OS_NAME="$(uname -s 2>/dev/null | sed 's/.*/\L&/')"

    if [[ "$(printf '%s\n%s\n' "$LATEST_VER" "$CURRENT_VER" | sort -V | head -n1)" == "$LATEST_VER" ]]; then
        return
    fi

    case "$(uname -m 2>/dev/null)" in
        amd64|x86_64) OS_ARCH="64" ;;
        arm64|armv8|aarch64) OS_ARCH="arm64-v8a" ;;
        *) die "unsupported cpu architecture." ;;
    esac

    # 下载内核文件和校验文件
    CORE_FILES=("Xray-$OS_NAME-$OS_ARCH.zip" "Xray-$OS_NAME-$OS_ARCH.zip.dgst")

    # 拼接下载链接
    for CORE_FILE in "${CORE_FILES[@]}"; do
        if ! curl -LsO "${GITHUB_PROXY}https://github.com/XTLS/Xray-core/releases/download/v$LATEST_VER/$CORE_FILE"; then
            die "download failed."
        fi
    done

    # 哈希校验
    if [[ "$(sha256sum "Xray-$OS_NAME-$OS_ARCH.zip" | awk '{print $1}')" != "$(grep '^SHA2-256=' "Xray-$OS_NAME-$OS_ARCH.zip.dgst" | sed 's/^SHA2-256= *//' | tr -d ' \t')" ]]; then
        die "sha256 checksum mismatch."
    fi

    unzip -qo "Xray-$OS_NAME-$OS_ARCH.zip" -d "$CORE_DIR/bin"
    chmod +x "$CORE_BIN" >/dev/null 2>&1
    rm -f "${CORE_DIR:?}"/bin/{LICENSE,README.md} >/dev/null 2>&1 || true
}

# 更新geofile
update_geo() {
    local -a GEO_FILES
    # 定义下载文件列表
    GEO_FILES=("geoip" "geosite")

    # 下载数据文件和校验文件
    for GEO_FILE in "${GEO_FILES[@]}"; do
        curl -LsO "${GITHUB_PROXY}https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/$GEO_FILE.dat"
        curl -LsO "${GITHUB_PROXY}https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/$GEO_FILE.dat.sha256sum"
        sha256sum -c "$GEO_FILE.dat.sha256sum" >/dev/null 2>&1
    done

    if [ -d "$CORE_DIR/bin" ]; then
        mv -f ./*.dat "$CORE_DIR/bin/" >/dev/null 2>&1
    fi
}

# 更新233boy xray脚本
update_sh() {
    local LATEST_VER CURRENT_VER TEMP_NAME
    LATEST_VER="$(curl -Ls "${GITHUB_PROXY}https://api.github.com/repos/233boy/Xray/releases" | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' | sort -rV | head -n1)"
    CURRENT_VER="$(sed -n 's/^is_sh_ver=v\(.*\)/\1/p' "$CORE_DIR/sh/xray.sh")"
    TEMP_NAME="$(random_char 5)"

    if [[ "$(printf '%s\n%s\n' "$LATEST_VER" "$CURRENT_VER" | sort -V | head -n1)" == "$LATEST_VER" ]]; then
        return
    fi

    if ! curl -Ls -o "$TEMP_NAME.zip" "${GITHUB_PROXY}https://github.com/233boy/Xray/releases/download/v$LATEST_VER/code.zip"; then
        die "download failed."
    fi
    unzip -qo "$TEMP_NAME.zip" -d "$SCRIPT_DIR"
    sed -i '/^get_ip() {/,/^}/ s#one.one.one.one#www.qualcomm.cn#g' "$SCRIPT_DIR/src/core.sh" >/dev/null 2>&1
    chmod +x "$SCRIPT_BIN" >/dev/null 2>&1
    rm -f "${SCRIPT_DIR:?}"/{LICENSE,README.md} >/dev/null 2>&1 || true
}

restart_xray() {
    local RESTART_CMD

    if [ -f /etc/alpine-release ]; then
        RESTART_CMD="rc-service xray restart"
    else
        RESTART_CMD="systemctl restart xray.service --quiet"
    fi

    for ((i=1; i<=3; i++)); do
        if eval "$RESTART_CMD" >/dev/null 2>&1; then
            return
        fi
        if [ "$i" -lt 3 ]; then
            sleep 1
        fi
    done
    die "Failed to restart xray service."
}

clear
check_root
check_bash
check_cdn
check_cmd
update_core
update_geo
update_sh
restart_xray
