#!/usr/bin/env sh
#
# Description: This script is used to build x-ui binary files for multiple architectures.
#
# Copyright (c) 2025 honeok <honeok@duck.com>
#
# References:
# https://github.com/FranzKafkaYu/x-ui
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

set \
    -o errexit \
    -o nounset

COMMANDS="curl jq"
for _CMD in $COMMANDS; do
    if ! command -v "$_CMD" >/dev/null 2>&1; then
        apk add --no-cache "$_CMD"
    fi
done

# FranzKafkaYu's x-ui was archived on November 14, 2024, with its latest version fixed at 0.3.4.4
# fetching the latest version via API might be my obsessive pursuit of this version-checking approach...
XUI_VERSION=$(curl -fsSL "https://api.github.com/repos/FranzKafkaYu/x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
XRAY_VERSION=$(curl -fsSL "https://api.github.com/repos/XTLS/Xray-core/releases" | jq -r 'map(select(.prerelease == true)) | sort_by(.created_at) | last | .tag_name' | sed 's/^v//')
readonly XUI_VERSION XRAY_VERSION
[ -z "$XUI_VERSION" ] && { printf "Error: Unable to obtain x-ui version!\n" >&2; exit 1; }
[ -z "$XRAY_VERSION" ] && { printf "Error: Unable to obtain xray version!\n" >&2; exit 1; }

# map system architecture to framework variable
case "$(uname -m)" in
    's390x')
        XUI_FRAMEWORK='s390x'
        XRAY_FRAMEWORK='s390x'
    ;;
    'x86_64' | 'x64' | 'amd64')
        XUI_FRAMEWORK='amd64'
        XRAY_FRAMEWORK='64'
    ;;
    'aarch64' | 'arm64')
        XUI_FRAMEWORK='arm64'
        XRAY_FRAMEWORK='arm64-v8a'
    ;;
    *)
        printf "Error: unsupported architecture: %s\n" "$(uname -m)" >&2; exit 1
    ;;
esac

cd /tmp || { printf 'Error: permission denied or directory does not exist\n' >&2; exit 1; }

# Extract x-ui
if ! curl -fsSL -O "https://github.com/FranzKafkaYu/x-ui/releases/download/${XUI_VERSION}/x-ui-linux-${XUI_FRAMEWORK}.tar.gz"; then
    printf 'Error: download x-ui failed, please check the network!\n' >&2; exit 1
fi
# Extract xray
if ! curl -fsSL -O "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-${XRAY_FRAMEWORK}.zip"; then
    printf 'Error: download xray failed, please check the network!\n' >&2; exit 1
fi

# Unzip xui and add execute permissions
tar -zxf "x-ui-linux-$XUI_FRAMEWORK.tar.gz"
if [ ! -x "x-ui/x-ui" ]; then chmod +x x-ui/x-ui; fi
# Unzip xray and add execute permissions
unzip -q "Xray-linux-$XRAY_FRAMEWORK.zip" -d ./xray
if [ ! -x "xray/xray" ]; then chmod +x xray/xray; fi