#!/usr/bin/env sh
#
# Description: This script is used to build the xray core for the 3x-ui runtime.
#
# Copyright (c) 2025 honeok <honeok@disroot.org>
#
# SPDX-License-Identifier: GPL-2.0-only

set -eux

XRAY_LVER="$1"
if [ -z "$XRAY_LVER" ]; then
    printf "Error: Unable to obtain xray version!\n" >&2
fi

# map system architecture to framework variable
case "$(uname -m)" in
    i*86)
        XRAY_FRAMEWORK="32"
    ;;
    x86_64 | amd64)
        XRAY_FRAMEWORK="64"
    ;;
    armv6*)
        XRAY_FRAMEWORK="arm32-v6"
    ;;
    armv7*)
        XRAY_FRAMEWORK="arm32-v7a"
    ;;
    armv8* | arm64 | aarch64)
        XRAY_FRAMEWORK="arm64-v8a"
    ;;
    ppc64le)
        XRAY_FRAMEWORK="ppc64le"
    ;;
    riscv64)
        XRAY_FRAMEWORK="riscv64"
    ;;
    s390x)
        XRAY_FRAMEWORK="s390x"
    ;;
    *)
        printf "Error: unsupported architecture: %s\n" "$(uname -m)" >&2; exit 1
    ;;
esac

cd /tmp || { printf "Error: permission denied or directory does not exist\n" >&2; exit 1; }
if ! wget --tries=5 -q "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_LVER}/Xray-linux-${XRAY_FRAMEWORK}.zip"; then
    printf "Error: download xray failed, please check the network!\n" >&2; exit 1
fi
# Unzip xray and add execute permissions
unzip -q "Xray-linux-$XRAY_FRAMEWORK.zip" -d ./xray
if [ ! -x xray/xray ]; then
    chmod +x xray/xray
fi