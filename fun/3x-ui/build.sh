#!/usr/bin/env sh
#
# Description: This script is used to build 3x-ui binary files for multiple architectures.
#
# Copyright (c) 2025 honeok <honeok@duck.com>
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

set -eux

command -v curl >/dev/null 2>&1 || apk add --no-cache curl

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