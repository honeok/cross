#!/bin/sh
#
# Description: This script is used to build Sing-box binary files for multiple architectures.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License, version 3 or later.
#
# This program is distributed WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# See the LICENSE file or <https://www.gnu.org/licenses/> for full license terms.

set \
    -o errexit \
    -o nounset

# Run default path
SINGBOX_WORKDIR="/etc/sing-box"
SINGBOX_BINDIR="$SINGBOX_WORKDIR/bin"
SINGBOX_CONFDIR="$SINGBOX_WORKDIR/conf"
SINGBOX_LOGDIR="/var/log/sing-box"
SINGBOX_LOGFILE="$SINGBOX_LOGDIR/access.log"

LATEST_VERSION=$(curl -fskL "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | awk -F '["v]' '/tag_name/{print $5}')
readonly LATEST_VERSION
[ -z "$LATEST_VERSION" ] && { echo "ERROR: Unable to obtain Sing-box version!"; exit 1; }

# Determine system arch based
case "$(uname -m)" in
    'x86' | 'i686' | 'i386')
        ARCH='386'   # 32-bit x86
    ;;
    'x86_64')
        ARCH='amd64' # 64-bit x86
    ;;
    'aarch64' | 'arm64')
        ARCH='arm64' # 64-bit ARM
    ;;
    'armv7l')
        ARCH='armv7' # 32-bit ARM
    ;;
    's390x')
        ARCH='s390x' # IBM S390x
    ;;
    *)
        ARCH=''
    ;;
esac
[ -z "$ARCH" ] && { echo "ERROR: Not supported OS ARCH!"; exit 1; }

# Create necessary directories
mkdir -p "$SINGBOX_WORKDIR" "$SINGBOX_BINDIR" "$SINGBOX_CONFDIR" "$SINGBOX_LOGDIR" 1>/dev/null
touch "$SINGBOX_LOGFILE" 1>/dev/null

cd "$SINGBOX_BINDIR" ||  { echo "ERROR: Failed to enter the sing-box bin directory!" ; exit 1;}

# Extract and install Sing-Box
if ! curl -fskL -O "https://github.com/SagerNet/sing-box/releases/download/v${LATEST_VERSION}/sing-box-${LATEST_VERSION}-linux-${ARCH}.tar.gz" ; then
    echo "ERROR: Download sing-Box failed, please check the network!" && exit 1
fi
tar zxf "sing-box-${LATEST_VERSION}-linux-${ARCH}.tar.gz" --strip-components=1 || { echo "ERROR: tar Sing-box package failed!"; exit 1; }
rm -f "sing-box-${LATEST_VERSION}-linux-${ARCH}.tar.gz" "LICENSE"
if [ ! -x "$SINGBOX_BINDIR/sing-box" ]; then
    chmod +x "$SINGBOX_BINDIR/sing-box"
fi
ln -s "$SINGBOX_BINDIR/sing-box" /usr/local/bin/sing-box
ln -s "$SINGBOX_BINDIR/sing-box" /usr/local/bin/sb