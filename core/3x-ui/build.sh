#!/usr/bin/env sh
# SPDX-License-Identifier: GPL-2.0
#
# Description: The script builds and prepares the xray-core runtime binary for 3x-ui.
# Copyright (c) 2025-2026 honeok <i@honeok.com>

set -eux

XRAY_VERSION="$1"
if [ -z "$XRAY_VERSION" ]; then
    echo >&2 "Error: Unable to obtain xray version!"
    exit 1
fi

# Determine system arch based
case "$TARGETOS/$TARGETARCH" in
linux/386) OS_ARCH="32" ;;
linux/amd64) OS_ARCH="64" ;;
linux/arm64 | linux/arm64/v8) OS_ARCH="arm64-v8a" ;;
linux/arm*)
    case "$(uname -m)" in
    armv6*) OS_ARCH="arm32-v6" ;;
    armv7*) OS_ARCH="arm32-v7a" ;;
    *)
        echo >&2 "Error: unsupported arm architecture: $(uname -m)"
        exit 1
        ;;
    esac
    ;;
linux/ppc64le) OS_ARCH="ppc64le" ;;
linux/riscv64) OS_ARCH="riscv64" ;;
linux/s390x) OS_ARCH="s390x" ;;
*)
    echo >&2 "Error: unsupported architecture: $TARGETARCH"
    exit 1
    ;;
esac

cd /tmp || exit 1
curl -Ls -O "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-${TARGETOS}-${OS_ARCH}.zip" || {
    echo >&2 "Error: download xray failed, please check the network!"
    exit 1
}
# Unzip xray and add execute permissions
unzip -q "Xray-${TARGETOS}-${OS_ARCH}.zip" -d ./xray
if [ ! -x xray/xray ]; then
    chmod +x xray/xray
fi
