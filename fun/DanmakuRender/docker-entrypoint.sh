#!/usr/bin/env sh
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# References:
# https://github.com/SmallPeaches/DanmakuRender
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

work_dir="/DanmakuRender"
danmaku_config_dir="$work_dir/configs"
danmaku_config_dir_temp="$work_dir/configs_temp"

if [ -d "$danmaku_config_dir" ] && [ -z "$(find "$danmaku_config_dir" -mindepth 1 -print -quit)" ]; then
    cp -rf "$danmaku_config_dir_temp"/* "$danmaku_config_dir/"
fi

if [ "$#" -eq 0 ]; then
    exec python3 -u "$work_dir/main.py" --config "$danmaku_config_dir" --skip_update
else
    exec "$@"
fi