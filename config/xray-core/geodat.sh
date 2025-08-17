#!/usr/bin/env bash
#
# Description: This script is used to fetches and updates the latest geo data file automatically.
#
# Copyright (c) 2025 honeok <i@honeok.com>
#
# Thanks:
# https://github.com/Loyalsoldier/v2ray-rules-dat
#
# SPDX-License-Identifier: GPL-2.0-only

set -eE

# 设置PATH环境变量
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH

# 各变量默认值
RANDOM_CHAR="$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 5)"
TEMP_DIR="/tmp/geodat_$RANDOM_CHAR"
XRAY_WORKDIR="/etc/xray"
XRAY_BINDIR="$XRAY_WORKDIR/bin"

# 定义下载文件列表
declare -a GEO_FILES=("geoip" "geosite")

# 终止信号捕获退出前清理操作
_exit() {
    local ERR_CODE="$?"
    rm -rf "$TEMP_DIR" >/dev/null 2>&1
    exit "$ERR_CODE"
}

# 终止信号捕获
trap '_exit' SIGINT SIGQUIT SIGTERM EXIT

# 临时工作目录
mkdir -p "$TEMP_DIR" >/dev/null 2>&1
cd "$TEMP_DIR" >/dev/null 2>&1

# 下载数据文件和校验文件
for GEO_FILE in "${GEO_FILES[@]}"; do
    curl --retry 2 -LsO "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/$GEO_FILE.dat"
    curl --retry 2 -LsO "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/$GEO_FILE.dat.sha256sum"
    sha256sum -c "$GEO_FILE.dat.sha256sum" >/dev/null 2>&1
done

[ -d "$XRAY_BINDIR" ] && mv -f ./*.dat "$XRAY_BINDIR"/
systemctl restart xray.service --quiet