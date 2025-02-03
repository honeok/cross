#!/bin/sh
#
# Description: Script for installing the necessary dependencies to build the containerized version of DanmakuRender.
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

biliupR_version=$(curl -fsL "https://api.github.com/repos/biliup/biliup-rs/releases/latest" | awk -F '["v]' '/tag_name/{print $5}')
readonly biliupR_version

case "$(uname -m)" in
    'x86_64')
        architecture='amd64'
        ;;
    'aarch64' | 'arm64')
        architecture='aarch64'
        ;;
    'armv7' | 'armv6')
        architecture='arm'
        ;;
    *)
        architecture=''
        ;;
esac

[ -z "$biliupR_version" ] && echo "ERROR: Unable to obtain biliupR version!" && exit 1
[ -z "$architecture" ] && echo "ERROR: Not supported OS Architecture!" && exit 1

if ! git clone https://github.com/SmallPeaches/DanmakuRender.git . -b v5; then
    echo "ERROR: Unable to obtain DanmakuRender source code!"
    exit 1
fi

if ! curl -fsL -O "https://github.com/biliup/biliup-rs/releases/download/v$biliupR_version/biliupR-v$biliupR_version-$architecture-linux.tar.xz" >/dev/null 2>&1; then
    echo "ERROR: Failed to download biliupR, please check the network!"
    exit 1
fi

tar xfv "biliupR-v$biliupR_version-$architecture-linux.tar.xz" --strip-components=1
rm -fv "biliupR-v$biliupR_version-$architecture-linux.tar.xz"
mv -fv biliup tools/