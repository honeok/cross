#!/usr/bin/env sh
#
# Description: This script builds Xray binaries for multiple architectures and prepares the Xray container runtime environment.
#
# Copyright (c) 2025 honeok <honeok@duck.com>
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

set -eux

# Run default path
XRAY_WORKDIR="/etc/xray"
XRAY_BINDIR="$XRAY_WORKDIR/bin"
XRAY_CONFDIR="$XRAY_WORKDIR/conf"
XRAY_LOGDIR="/var/log/xray"
XRAY_ACCESS_LOG="$XRAY_LOGDIR/access.log"
XRAY_ERROR_LOG="$XRAY_LOGDIR/error.log"

command -v curl >/dev/null 2>&1 || apk add --no-cache curl

build_xray() {
    XRAY_VERSION=$(curl -fsL --retry 5 "https://api.github.com/repos/XTLS/Xray-core/releases/latest" | awk -F '["v]' '/tag_name/{print $5}')
    readonly XRAY_VERSION
    [ -z "$XRAY_VERSION" ] && { printf 'Error: Unable to obtain xray version!\n' >&2; exit 1; }

    # map system architecture to framework variable
    case "$(uname -m)" in
        i*86)
            XRAY_FRAMEWORK='32'
        ;;
        x86_64 | amd64)
            XRAY_FRAMEWORK='64'
        ;;
        armv6*)
            XRAY_FRAMEWORK='arm32-v6'
        ;;
        armv7*)
            XRAY_FRAMEWORK='arm32-v7a'
        ;;
        armv8* | arm64 | aarch64)
            XRAY_FRAMEWORK='arm64-v8a'
        ;;
        ppc64le)
            XRAY_FRAMEWORK='ppc64le'
        ;;
        riscv64)
            XRAY_FRAMEWORK='riscv64'
        ;;
        s390x)
            XRAY_FRAMEWORK='s390x'
        ;;
        *)
            printf "Error: unsupported architecture: %s\n" "$(uname -m)" >&2; exit 1
        ;;
    esac

    cd /tmp || { printf 'Error: permission denied or directory does not exist\n' >&2; exit 1; }

    if ! curl -fsL -O "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-${XRAY_FRAMEWORK}.zip"; then
        printf 'Error: download xray failed, please check the network!\n' >&2; exit 1
    fi

    # Unzip xray and add execute permissions
    unzip -q "Xray-linux-$XRAY_FRAMEWORK.zip" -d ./xray
    if [ ! -x "xray/xray" ]; then chmod +x xray/xray; fi
}

pre_config() {
    mkdir -p "$XRAY_WORKDIR" "$XRAY_BINDIR" "$XRAY_CONFDIR" "$XRAY_LOGDIR" >/dev/null 2>&1
    touch "$XRAY_ACCESS_LOG" >/dev/null 2>&1
    touch "$XRAY_ERROR_LOG" >/dev/null 2>&1
    ln -sf "$XRAY_BINDIR/xray" /usr/local/bin/xray
}

case "$1" in
    xray) build_xray ;;
    pre) pre_config ;;
    *) printf 'Error: Invalid parameter or no parameter!\n' >&2; exit 1; ;;
esac