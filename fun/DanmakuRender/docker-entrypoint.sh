#!/bin/sh

work_dir="/DanmakuRender"
danmaku_config_dir="/DanmakuRender/configs"
danmaku_config_dir_temp="/DanmakuRender/configs_temp"

if [ -d "$danmaku_config_dir" ] && [ -z "$(ls -A "$danmaku_config_dir" 2>/dev/null)" ]; then
    cp -rf "$danmaku_config_dir_temp"/* "$danmaku_config_dir/"
fi

if [ "$#" -eq 0 ]; then
    exec python3 -u "$work_dir/main.py" --config "$danmaku_config_dir" --skip_update
else
    exec "$@"
fi