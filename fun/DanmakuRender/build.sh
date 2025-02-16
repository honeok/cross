#!/usr/bin/env sh
#
# Description: Script for installing the necessary dependencies to build the containerized version of DanmakuRender.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

set \
    -o errexit \
    -o nounset

biliupR_version=$(curl -fsL "https://api.github.com/repos/biliup/biliup-rs/releases/latest" | awk -F '["v]' '/tag_name/{print $5}')
readonly biliupR_version

case "$(uname -m)" in
    'x86_64')
        Architecture='x86_64'
    ;;
    'aarch64' | 'arm64')
        Architecture='aarch64'
    ;;
    'armv7l')
        Architecture='arm'
    ;;
    *)
        Architecture=''
    ;;
esac

[ -z "$biliupR_version" ] && echo "ERROR: Unable to obtain biliupR version!" && exit 1
[ -z "$Architecture" ] && echo "ERROR: Not supported OS Architecture!" && exit 1

if ! git clone --branch v5 --single-branch https://github.com/SmallPeaches/DanmakuRender.git; then
    echo "ERROR: Unable to obtain DanmakuRender source code!"
    exit 1
fi

if ! curl -fsL -O "https://github.com/biliup/biliup-rs/releases/download/v$biliupR_version/biliupR-v$biliupR_version-$Architecture-linux.tar.xz" >/dev/null 2>&1; then
    echo "ERROR: Failed to download biliupR, please check the network!"
    exit 1
fi

mv -f DanmakuRender/* .
rm -rf DanmakuRender
tar xf "biliupR-v$biliupR_version-$Architecture-linux.tar.xz" --strip-components=1
rm -f "biliupR-v$biliupR_version-$Architecture-linux.tar.xz"
mv -f biliup tools/