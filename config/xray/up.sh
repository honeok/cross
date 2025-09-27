#!/usr/bin/env bash
#
# Description: This script is used to automatically update xray-core and the latest geoip/geosite data.
#
# Copyright (c) 2025 honeok <i@honeok.com>
# SPDX-License-Identifier: GPL-2.0
#
# Thanks:
# https://github.com/XTLS/Xray-core
# https://github.com/bin456789/reinstall
# https://github.com/Loyalsoldier/v2ray-rules-dat

set -eE

# 设置PATH环境变量
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH
# 环境变量用于在debian或ubuntu操作系统中设置非交互式 (noninteractive) 安装模式
export DEBIAN_FRONTEND=noninteractive

# 各变量默认值
TEMP_DIR="$(mktemp -d)"
XRAY_WORKDIR="/etc/xray"
XRAY_BINDIR="$XRAY_WORKDIR/bin"
XRAY_CORE="$XRAY_BINDIR/xray"

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

# 更新内核
bump_version() {
    local XRAY_LVER XRAY_CVER OS_NAME OS_ARCH
    local -a CORE_FILES

    XRAY_LVER="$(curl -Ls https://api.github.com/repos/XTLS/Xray-core/releases | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' | sort -Vr | head -n1)"
    XRAY_CVER="$("$XRAY_CORE" version 2>/dev/null | head -n1 | sed -n 's/^Xray \([0-9.]\+\).*/\1/p')"
    OS_NAME="$(uname -s 2>/dev/null | sed 's/.*/\L&/')"

    if [[ "$(printf '%s\n%s\n' "$XRAY_LVER" "$XRAY_CVER" | sort -V | head -n1)" == "$XRAY_LVER" ]]; then
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
        if ! curl -LsO "https://github.com/XTLS/Xray-core/releases/download/v$XRAY_LVER/$CORE_FILE"; then
            die "download failed, please check the network."
        fi
    done

    # 哈希校验
    if [[ "$(sha256sum "Xray-$OS_NAME-$OS_ARCH.zip" | awk '{print $1}')" != "$(grep '^SHA2-256=' "Xray-$OS_NAME-$OS_ARCH.zip.dgst" | sed 's/^SHA2-256= *//' | tr -d ' \t')" ]]; then
        die "sha256 checksum mismatch."
    fi

    unzip -q "Xray-$OS_NAME-$OS_ARCH.zip"
    if [ ! -x ./xray ]; then
        chmod +x ./xray >/dev/null 2>&1
    fi
    if [ -x "$XRAY_CORE" ]; then
        mv -f ./xray "$XRAY_CORE" >/dev/null 2>&1
    fi
}

# 更新geofile
geo_file() {
    local -a GEO_FILES
    # 定义下载文件列表
    GEO_FILES=("geoip" "geosite")

    # 下载数据文件和校验文件
    for GEO_FILE in "${GEO_FILES[@]}"; do
        curl -LsO "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/$GEO_FILE.dat"
        curl -LsO "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/$GEO_FILE.dat.sha256sum"
        sha256sum -c "$GEO_FILE.dat.sha256sum" >/dev/null 2>&1
    done

    if [ -d "$XRAY_BINDIR" ]; then
        mv -f ./*.dat "$XRAY_BINDIR"/ >/dev/null 2>&1
    fi
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
check_cmd
bump_version
geo_file
restart_xray
