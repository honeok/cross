#!/usr/bin/env sh
#
# Description: This script builds Xray binaries for multiple architectures and prepares the Xray container runtime environment.
#
# Copyright (c) 2025 honeok <honeok@disroot.org>
#
# SPDX-License-Identifier: GPL-2.0-only

set -eux

# Default value
XRAY_WORKDIR="/etc/xray"
XRAY_BINDIR="$XRAY_WORKDIR/bin"
XRAY_CONFDIR="$XRAY_WORKDIR/conf"
XRAY_LOGDIR="/var/log/xray"
XRAY_ACCESS_LOG="$XRAY_LOGDIR/access.log"
XRAY_ERROR_LOG="$XRAY_LOGDIR/error.log"

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 [--build <version>] [--before]"
    exit 0
fi

build_xray() {
    if [ -z "$XRAY_LVER" ]; then
        echo >&2 "Error: Missing version. Use --build <version>"; exit 1
    fi
    # Determine system arch based
    case "$TARGETOS/$TARGETARCH" in
        linux/386 ) OS_ARCH="32";;
        linux/amd64 ) OS_ARCH="64" ;;
        linux/arm64 | linux/arm64/v8 ) OS_ARCH="arm64-v8a" ;;
        linux/arm* )
            case "$(uname -m)" in
                armv6* ) OS_ARCH="arm32-v6" ;;
                armv7* ) OS_ARCH="arm32-v7a" ;;
                * ) echo >&2 "Error: unsupported arm architecture: $(uname -m)"; exit 1 ;;
            esac ;;
        linux/ppc64le ) OS_ARCH="ppc64le" ;;
        linux/riscv64 ) OS_ARCH="riscv64" ;;
        linux/s390x ) OS_ARCH="s390x" ;;
        * ) echo >&2 "Error: unsupported architecture: $TARGETARCH"; exit 1 ;;
    esac
    cd /tmp || { echo >&2 "Error: permission denied."; exit 1; }
    # Extract and install xray-core
    curl -fsL -O "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_LVER}/Xray-${TARGETOS}-${OS_ARCH}.zip" || {
        echo >&2 "Error: download xray failed, please check the network!"; exit 1;
    }
    unzip -q "Xray-${TARGETOS}-${OS_ARCH}.zip" -d ./xray
    if [ ! -x xray/xray ]; then
        chmod +x xray/xray
    fi
}

before_script() {
    # Create necessary directories
    mkdir -p "$XRAY_WORKDIR" "$XRAY_BINDIR" "$XRAY_CONFDIR" "$XRAY_LOGDIR" >/dev/null 2>&1
    touch "$XRAY_ACCESS_LOG" "$XRAY_ERROR_LOG" >/dev/null 2>&1
    ln -sf "$XRAY_BINDIR/xray" /usr/local/bin/xray
}

while [ "$#" -ge 1 ]; do
    case "$1" in
        --build )
            shift
            XRAY_LVER="$1"
            build_xray
            shift
        ;;
        --before )
            before_script
            shift
        ;;
        * )
            echo >&2 "Error: Unknown parameter: $1"; exit 1
        ;;
    esac
done