#!/usr/bin/env sh
#
# Description: This script is used to build Sing-box binary files for multiple architectures.
#
# Copyright (c) 2025 honeok <honeok@disroot.org>
#
# SPDX-License-Identifier: GPL-2.0-only

set -eux

# Default value
SINGBOX_LVER="$1"
SINGBOX_WORKDIR="/etc/sing-box"
SINGBOX_BINDIR="$SINGBOX_WORKDIR/bin"
SINGBOX_CONFDIR="$SINGBOX_WORKDIR/conf"
SINGBOX_LOGDIR="/var/log/sing-box"
SINGBOX_LOGFILE="$SINGBOX_LOGDIR/access.log"

# Determine system arch based
case "$TARGETOS/$TARGETARCH" in
    linux/386 ) OS_ARCH="386" ;;
    linux/amd64 ) OS_ARCH="amd64" ;;
    linux/arm64 | linux/arm64/v8 ) OS_ARCH="arm64" ;;
    linux/arm* )
        case "$(uname -m)" in
            armv6* ) OS_ARCH="armv6" ;;
            armv7* ) OS_ARCH="armv7" ;;
            * ) echo >&2 "Error: unsupported arm architecture: $(uname -m)"; exit 1 ;;
        esac ;;
    linux/ppc64le ) OS_ARCH="ppc64le" ;;
    linux/riscv64 ) OS_ARCH="riscv64" ;;
    linux/s390x ) OS_ARCH="s390x" ;;
    * ) echo >&2 "Error: unsupported architecture: $TARGETARCH"; exit 1 ;;
esac

# Create necessary directories
mkdir -p "$SINGBOX_WORKDIR" "$SINGBOX_BINDIR" "$SINGBOX_CONFDIR" "$SINGBOX_LOGDIR" >/dev/null 2>&1
touch "$SINGBOX_LOGFILE" >/dev/null 2>&1

cd "$SINGBOX_BINDIR" || { echo >&2 "Error: Failed to enter the sing-box bin directory!"; exit 1; }
# Extract and install Sing-Box
if ! curl -fsL -O "https://github.com/SagerNet/sing-box/releases/download/v${SINGBOX_LVER}/sing-box-${SINGBOX_LVER}-${TARGETOS}-${OS_ARCH}.tar.gz"; then
    echo >&2 "Error: Download Sing-Box failed, please check the network!"; exit 1
fi
tar -zxf "sing-box-${SINGBOX_LVER}-${TARGETOS}-${OS_ARCH}.tar.gz" --strip-components=1 || { echo >&2 "Error: tar sing-box package failed!"; exit 1; }
find . -mindepth 1 -maxdepth 1 ! -name 'sing-box' -exec rm -rf {} +
[ ! -x "$SINGBOX_BINDIR/sing-box" ] && chmod +x "$SINGBOX_BINDIR/sing-box"
ln -sf "$SINGBOX_BINDIR/sing-box" /usr/local/bin/sing-box