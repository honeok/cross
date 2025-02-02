#!/bin/sh
#
# Description: This script is used to build Sing-box binary files for multiple architectures.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# License Information:
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License, version 3 or later.
#
# This program is distributed WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <https://www.gnu.org/licenses/>.

set \
    -o errexit \
    -o nounset \
    -o xtrace

os_name=$(grep "^ID=" /etc/*release | awk -F'=' '{print $2}' | sed 's/"//g')
readonly os_name

[ "$os_name" != "alpine" ] && echo "This script is only for Alpine Linux." && exit 1

sb_version=$(curl -fsL "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | awk -F '["v]' '/tag_name/{print $5}')
readonly sb_version

case "$(uname -m)" in
    'x86' | 'i686' | 'i386')
        architecture='386'
        ;;
    'x86_64')
        architecture='amd64'
        ;;
    'aarch64' | 'arm64')
        architecture='arm64'
        ;;
    'armv7l')
        architecture='armv7'
        ;;
    's390x')
        architecture='s390x'
        ;;
    *)
        architecture=''
        ;;
esac

[ -z "$architecture" ] && echo "ERROR: Not supported OS Architecture!" && exit 1
[ -z "$sb_version" ] && echo "ERROR: Unable to obtain Sing box version!" && exit 1

if ! curl -fsL -O "https://github.com/SagerNet/sing-box/releases/download/v${sb_version}/sing-box-${sb_version}-linux-${architecture}.tar.gz" >/dev/null 2>&1; then
    echo "ERROR: Download single box failed, please check the network!"
    exit 1
fi

tar zxf "sing-box-${sb_version}-linux-${architecture}.tar.gz" --strip-components=1
rm -fv "sing-box-${sb_version}-linux-${architecture}.tar.gz" "LICENSE"
mv -f "sing-box" "/usr/local/bin/sing-box"

if [ ! -x "/usr/local/bin/sing-box" ]; then
    chmod +x "/usr/local/bin/sing-box"
fi