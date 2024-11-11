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
center_passwd="xxxxxxxxxx"

# 二次确认
echo -e "${yellow}注意: 当前项目为${project_name}，确认无误后按任意键继续${white}"
read -n 1 -s -r -p ""
echo ""

cd "$local_update_path" || exit
rm -fr *

# 从中心服务器下载最新更新包
if command -v sshpass &> /dev/null; then
    sshpass -p "$center_passwd" scp -o StrictHostKeyChecking=no "root@$center_host:$remote_update_source" "$local_update_path/" \
        && _green "从中心拉取Updategame.tar.gz成功！" || { _red "下载失败，请检查网络连接或密码"; exit 1; }
else
    _red "sshpass未安装，请先安装sshpass"
    exit 1
fi

tar xvf "$local_update_path/updategame.tar.gz" \
    && _green "解压成功" || { _red "解压失败"; exit 1; }

for i in {1..5}; do
    dest_dir="/data/server$i/game"
    _yellow "正在处理server$i"

    if [ ! -d "$dest_dir" ]; then
        _red "目录${dest_dir}不存在，跳过server${i}更新！"
        continue
    fi

    \cp -fr "$local_update_path/app/"* "$dest_dir/"

    cd "$dest_dir" || exit
    ./server.sh reload
    _green "server${i}更新成功！"
    echo "-------------------"
done
