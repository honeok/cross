#!/bin/bash
## Author: honeok
## Blog: www.honeok.com
## Github: https://github.com/honeok

## set -x

yellow='\033[93m'        # 亮黄色
red='\033[91m'           # 亮红色
green='\033[92m'         # 亮绿色
white='\033[0m'          # 重置

_yellow() { echo -e ${yellow}$@${white}; }
_red() { echo -e ${red}$@${white}; }
_green() { echo -e ${green}$@${white}; }

project_name="CBT4"
local_update_path="/data/update"
remote_update_source="/data/update/updategame.tar.gz"
center_host="10.46.96.254"
center_passwd="c4h?itwj5ENi"

# 二次确认
echo -e "${yellow}注意: 当前项目为 ${project_name}，确认无误后按任意键继续${white}"
read -n 1 -s -r -p ""
echo ""

cd "$local_update_path" || exit
rm -fr *

# 从中心服务器下载最新更新包
sshpass -p "$center_passwd" scp -o StrictHostKeyChecking=no "root@$center_host:$remote_update_source" "$local_update_path/" \
    && _green "从中心拉取Updategame.tar.gz成功！" || { _red "下载失败，请检查网络连接或密码"; exit 1; }

tar xvf "$local_update_path/updategame.tar.gz" \
    && _green "解压成功" || { _red "解压失败"; exit 1; }

for i in {1..5}; do
    dest_dir="/data/server$i/game"
    _yellow "正在处理server$i"

    \cp -fr "$local_update_path/app/"* "$dest_dir/"

    cd "$dest_dir" || continue
    ./server.sh reload
    _green "server$i 更新成功！"
done