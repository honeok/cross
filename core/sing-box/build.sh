#!/usr/bin/env sh
#
# Description: This script is used to build Sing-box binary files for multiple architectures.
#
# Copyright (c) 2025 honeok <honeok@disroot.org>
#
# SPDX-License-Identifier: GPL-2.0-only

set -eux

SINGBOX_LVER="$1"
# Run default path
SINGBOX_WORKDIR="/etc/sing-box"
SINGBOX_BINDIR="$SINGBOX_WORKDIR/bin"
SINGBOX_CONFDIR="$SINGBOX_WORKDIR/conf"
SINGBOX_LOGDIR="/var/log/sing-box"
SINGBOX_LOGFILE="$SINGBOX_LOGDIR/access.log"

command -v curl >/dev/null 2>&1 || apk add --no-cache curl

# Determine system arch based
case "$(uname -m)" in
    i*86 | x86)
        SINGBOX_FRAMEWORK="386" # 32-bit x86
    ;;
    x86_64 | amd64)
        SINGBOX_FRAMEWORK="amd64" # 64-bit x86
    ;;
    armv6*)
        SINGBOX_FRAMEWORK="armv6" # ARMv6
    ;;
    armv7*)
        SINGBOX_FRAMEWORK="armv7" # 32-bit ARM
    ;;
    arm64 | aarch64)
        SINGBOX_FRAMEWORK="arm64" # 64-bit ARM
    ;;
    ppc64le)
        SINGBOX_FRAMEWORK="ppc64le" # PowerPC 64-bit
    ;;
    riscv64)
        SINGBOX_FRAMEWORK="riscv64" # RISC-V 64-bit
    ;;
    s390x)
        SINGBOX_FRAMEWORK="s390x" # IBM S390x
    ;;
    *)
        printf "Error: unsupported architecture: %s\n" "$(uname -m)" >&2; exit 1
    ;;
esac

# Create necessary directories
mkdir -p "$SINGBOX_WORKDIR" "$SINGBOX_BINDIR" "$SINGBOX_CONFDIR" "$SINGBOX_LOGDIR" >/dev/null 2>&1
touch "$SINGBOX_LOGFILE" >/dev/null 2>&1

cd "$SINGBOX_BINDIR" || { printf "Error: Failed to enter the sing-box bin directory!\n"; exit 1; }
# Extract and install Sing-Box
if ! curl -fsL -O "https://github.com/SagerNet/sing-box/releases/download/v${SINGBOX_LVER}/sing-box-${SINGBOX_LVER}-linux-${SINGBOX_FRAMEWORK}.tar.gz"; then
    printf "Error: Download sing-Box failed, please check the network!\n" >&2; exit 1
fi
tar -zxf "sing-box-${SINGBOX_LVER}-linux-${SINGBOX_FRAMEWORK}.tar.gz" --strip-components=1 || { printf "Error: tar Sing-box package failed!\n"; exit 1; }
find . -mindepth 1 -maxdepth 1 ! -name 'sing-box' -exec rm -rf {} +
[ ! -x "$SINGBOX_BINDIR/sing-box" ] && chmod +x "$SINGBOX_BINDIR/sing-box"
ln -s "$SINGBOX_BINDIR/sing-box" /usr/local/bin/sing-box