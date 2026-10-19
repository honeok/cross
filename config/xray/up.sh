#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0
#
# Description: This script is used to automatically update xray-core and the latest geoip/geosite data.
# Copyright (c) 2025-2026 honeok <i@honeok.com>
#
# Thanks:
# https://github.com/233boy/Xray
# https://github.com/XTLS/Xray-core
# https://github.com/bin456789/reinstall

set -eE

# 设置PATH环境变量
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH
# 环境变量用于在debian或ubuntu操作系统中设置非交互式 (noninteractive) 安装模式
export DEBIAN_FRONTEND=noninteractive

# 各变量默认值
TEMP_DIR="$(mktemp -d 2> /dev/null)"

: "${CORE_NAME:="xray"}"
: "${CORE_DIR:="/etc/$CORE_NAME"}"
: "${CORE_BIN:="$CORE_DIR/bin/$CORE_NAME"}"
: "${SCRIPT_DIR:="$CORE_DIR/sh"}"
: "${SCRIPT_BIN:="/usr/local/bin/$CORE_NAME"}" # 软连接 /etc/xray/sh/xray.sh

# 终止信号捕获
trap 'rm -rf "${TEMP_DIR:?}" > /dev/null 2>&1' SIGINT SIGTERM EXIT

clear() {
    [ -t 1 ] && tput clear 2> /dev/null || printf "\033[2J\033[H" || command clear
}

die() {
    echo >&2 "Error: $*"
    exit 1
}

# 临时工作目录
cd "$TEMP_DIR" > /dev/null 2>&1 || die "Unable to enter the work path."

get_cmd_path() {
    # arch 云镜像不带 which
    # command -v 包括脚本里面的方法
    # ash 无效
    type -f -p "$1"
}

is_have_cmd() {
    get_cmd_path "$1" > /dev/null 2>&1
}

install_pkg() {
    for pkg in "$@"; do
        if is_have_cmd dnf; then
            dnf install -y "$pkg"
        elif is_have_cmd yum; then
            yum install -y "$pkg"
        elif is_have_cmd apt-get; then
            apt-get update
            apt-get install -y -q "$pkg"
        elif is_have_cmd apk; then
            apk add --no-cache "$pkg"
        else
            die "The package manager is not supported."
        fi
    done
}

curl() {
    local i rc

    is_have_cmd curl || install_pkg curl
    # 添加 --fail 不然404退出码也为0
    # 32位cygwin已停止更新, 证书可能有问题, 添加 --insecure
    # centos7 curl 不支持 --retry-connrefused --retry-all-errors 因此手动 retry
    for ((i = 1; i <= 3; i++)); do
        if command curl --connect-timeout 10 --fail --insecure "$@"; then
            return 0
        else
            rc="$?"
            if ((rc == 22 || i == 3)); then
                return "$rc"
            fi
            sleep 1
        fi
    done
}

is_in_alpine() {
    [ -f /etc/alpine-release ]
}

to_lower() {
    tr '[:upper:]' '[:lower:]'
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        die "This script must be run as root."
    fi
}

# 安装必要的软件包
check_cmd() {
    local -a pkgs
    pkgs=("curl" "unzip")

    for pkg in "${pkgs[@]}"; do
        if ! is_have_cmd "$pkg" > /dev/null 2>&1; then
            install_pkg "$pkg"
        fi
    done
}

# 更新 xray 内核
update_core() {
    local latest_ver current_ver os_name os_arch core_file
    local -a core_files

    latest_ver="$(curl -Ls https://api.github.com/repos/XTLS/Xray-core/releases | sed -nE 's/.*"tag_name": *"v([^"]+)".*/\1/p' | sort -V | tail -n 1)"
    current_ver="$("$CORE_BIN" version 2> /dev/null | head -n 1 | sed -n 's/^Xray \([0-9.]\+\).*/\1/p')"
    os_name="$(uname -s 2> /dev/null | to_lower)"

    if [[ "$(printf '%s\n%s\n' "$latest_ver" "$current_ver" | sort -V | head -n 1)" == "$latest_ver" ]]; then
        return
    fi

    case "$(uname -m 2> /dev/null | to_lower)" in
    amd64 | x86_64) os_arch="64" ;;
    arm64 | aarch64) os_arch="arm64-v8a" ;;
    *) die "unsupported cpu architecture." ;;
    esac

    # 下载内核文件和校验文件
    core_files=("Xray-$os_name-$os_arch.zip" "Xray-$os_name-$os_arch.zip.dgst")

    # 拼接下载链接
    for core_file in "${core_files[@]}"; do
        curl -L -O "https://github.com/XTLS/Xray-core/releases/download/v$latest_ver/$core_file" || die "download failed."
    done

    # 哈希校验
    if [[ "$(sha256sum "Xray-$os_name-$os_arch.zip" | awk '{print $1}')" != "$(grep '^SHA2-256=' "Xray-$os_name-$os_arch.zip.dgst" | sed 's/^SHA2-256= *//' | tr -d ' \t')" ]]; then
        die "sha256 checksum mismatch."
    fi

    unzip -qo "Xray-$os_name-$os_arch.zip" -d "$CORE_DIR/bin"
    chmod +x "$CORE_BIN" > /dev/null 2>&1
    rm -f "${CORE_DIR:?}"/bin/{LICENSE,README.md} > /dev/null 2>&1 || true
}

# 更新 geofile
update_geo() {
    local -a geo_paths
    local geo_path geo_file
    geo_paths=("geoip/geoip-full" "geosite/geosite")

    # 下载数据文件和校验文件
    for geo_path in "${geo_paths[@]}"; do
        geo_file="${geo_path##*/}.dat"

        curl -L "https://github.com/XTLS/Xray-rules-dat/raw/release/$geo_path.dat" -o "$geo_file"
        curl -L "https://github.com/XTLS/Xray-rules-dat/raw/release/$geo_path.dat.sha256sum" -o "$geo_file.sha256sum"
        sha256sum -c "$geo_file.sha256sum" > /dev/null 2>&1
    done

    # 重命名 geoip 文件
    mv -f geoip-full.dat geoip.dat
    if [ -d "$CORE_DIR/bin" ]; then
        mv -f ./*.dat "$CORE_DIR/bin/" > /dev/null 2>&1
    fi
}

# 更新 233boy xray 脚本
update_sh() {
    local latest_ver current_ver
    latest_ver="$(curl -Ls https://api.github.com/repos/233boy/Xray/releases | sed -nE 's/.*"tag_name": *"v([^"]+)".*/\1/p' | sort -V | tail -n 1)"
    current_ver="$(sed -n 's/^is_sh_ver=v\(.*\)/\1/p' "$CORE_DIR/sh/xray.sh")"

    if [[ "$(printf '%s\n%s\n' "$latest_ver" "$current_ver" | sort -V | head -n 1)" == "$latest_ver" ]]; then
        return
    fi

    curl -L -O "https://github.com/233boy/Xray/releases/download/v$latest_ver/code.zip" || die "download failed."
    unzip -qo code.zip -d "$SCRIPT_DIR"
    sed -i '/^get_ip() {/,/^}/ s#one.one.one.one#www.qualcomm.cn#g' "$SCRIPT_DIR/src/core.sh" > /dev/null 2>&1
    chmod +x "$SCRIPT_BIN" > /dev/null 2>&1
    rm -f "${SCRIPT_DIR:?}"/{LICENSE,README.md} > /dev/null 2>&1 || true
}

restart_xray() {
    local restart_cmd

    if is_in_alpine; then
        restart_cmd="service xray restart"
    else
        restart_cmd="systemctl restart xray.service"
    fi

    for ((i = 1; i <= 3; i++)); do
        if eval "$restart_cmd" > /dev/null 2>&1; then
            return
        fi
    done
    die "Failed to restart xray service."
}

clear
check_root
check_cmd
update_core
update_geo
update_sh
restart_xray
