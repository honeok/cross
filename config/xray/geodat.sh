#!/usr/bin/env bash
#
# Description: This script is used to fetches and updates the latest geo data file automatically.
#
# Copyright (c) 2025 honeok <i@honeok.com>
#
# Thanks:
# https://github.com/Loyalsoldier/v2ray-rules-dat
#
# SPDX-License-Identifier: GPL-2.0

set -eE

# 各变量默认值
TEMP_DIR="$(mktemp -d)"
XRAY_WORKDIR="/etc/xray"
XRAY_BINDIR="$XRAY_WORKDIR/bin"

# 终止信号捕获
trap 'rm -rf "${TEMP_DIR:?}" >/dev/null 2>&1' SIGINT SIGTERM EXIT

# 临时工作目录
cd "$TEMP_DIR" >/dev/null 2>&1

# 定义下载文件列表
declare -a GEO_FILES=("geoip" "geosite")

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

# 下载数据文件和校验文件
for GEO_FILE in "${GEO_FILES[@]}"; do
    curl -LsO "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/$GEO_FILE.dat"
    curl -LsO "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/$GEO_FILE.dat.sha256sum"
    sha256sum -c "$GEO_FILE.dat.sha256sum" >/dev/null 2>&1
done

[ -d "$XRAY_BINDIR" ] && mv -f ./*.dat "$XRAY_BINDIR"/
systemctl restart xray.service --quiet