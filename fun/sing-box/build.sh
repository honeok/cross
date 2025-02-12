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

Singbox_version=$(curl -fskL "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | awk -F '["v]' '/tag_name/{print $5}')
readonly Singbox_version

case "$(uname -m)" in
    'x86' | 'i686' | 'i386')
        Architecture='386'
    ;;
    'x86_64')
        Architecture='amd64'
    ;;
    'aarch64' | 'arm64')
        Architecture='arm64'
    ;;
    'armv7l')
        Architecture='armv7'
    ;;
    's390x')
        Architecture='s390x'
    ;;
    *)
        Architecture=''
    ;;
esac

[ -z "$Singbox_version" ] && { echo "ERROR: Unable to obtain Sing-box version!" && exit 1 ;}
[ -z "$Architecture" ] && { echo "ERROR: Not supported OS Architecture!" && exit 1 ;}

if ! curl -fsL "https://github.com/SagerNet/sing-box/releases/download/v${Singbox_version}/sing-box-${Singbox_version}-linux-${Architecture}.tar.gz" -o "sing-box-${Singbox_version}-linux-${Architecture}.tar.gz" ; then
    echo "ERROR: Download single box failed, please check the network!"
    exit 1
fi

tar zxf "sing-box-${Singbox_version}-linux-${Architecture}.tar.gz" --strip-components=1
rm -f "sing-box-${Singbox_version}-linux-${Architecture}.tar.gz" "LICENSE"
mv -f "sing-box" "/usr/local/bin/sing-box"
[ ! -x "/usr/local/bin/sing-box" ] && chmod +x "/usr/local/bin/sing-box"