#!/usr/bin/env bash
#
# Description: Nezha Monitoring Installation Script
# System Required: CentOS 7+ / Debian 8+ / Ubuntu 16+ / Alpine 3+ / Arch
# Github: https://github.com/nezhahq/nezha
#
# Modified By: honeok <yihaohey@gmail.com>
# https://github.com/honeok/cross/blob/master/nezha/install.sh

NZ_BASE_PATH="/opt/nezha"
NZ_DASHBOARD_PATH="${NZ_BASE_PATH}/dashboard"
NZ_AGENT_PATH="${NZ_BASE_PATH}/agent"
NZ_DASHBOARD_SERVICE="/etc/systemd/system/nezha-dashboard.service"
NZ_DASHBOARD_SERVICERC="/etc/init.d/nezha-dashboard"
NZ_VERSION="v0.00.0"
SCRIPT_v="2024-11-30"

yellow='\033[1;33m'
red='\033[1;31m'
green='\033[1;32m'
cyan='\033[1;36m'
white='\033[0m'
_red() { echo -e ${red}$@${white}; }
_green() { echo -e ${green}$@${white}; }
_yellow() { echo -e ${yellow}$@${white}; }

export PATH="$PATH:/usr/local/bin"

os_arch=""
[ -e /etc/os-release ] && grep -i "PRETTY_NAME" /etc/*release | grep -qi "alpine" && os_alpine='1'

sudo() {
    myEUID=$(id -ru)
    if [ "$myEUID" -ne 0 ]; then
        if command -v sudo > /dev/null 2>&1; then
            command sudo "$@"
        else
            _red "错误: 您的系统未安装sudo，因此无法进行该项操作。"
            exit 1
        fi
    else
        "$@"
    fi
}

check_systemd() {
    if [ "$os_alpine" != 1 ] && ! command -v systemctl >/dev/null 2>&1; then
        _red "不支持此系统: 未找到systemctl命令"
        exit 1
    fi
}

geo_check() {
    api_list="https://blog.cloudflare.com/cdn-cgi/trace https://dash.cloudflare.com/cdn-cgi/trace https://developers.cloudflare.com/cdn-cgi/trace"
    ua="Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0"
    set -- "$api_list"
    for url in $api_list; do
        text="$(curl -A "$ua" -m 10 -s "$url")"
        endpoint="$(echo "$text" | sed -n 's/.*h=\([^ ]*\).*/\1/p')"
        if echo "$text" | grep -qw 'CN'; then
            isCN=true
            break
        elif echo "$url" | grep -q "$endpoint"; then
            break
        fi
    done
}

pre_check() {
    umask 077

    ## os_arch
    if uname -m | grep -q 'x86_64'; then
        os_arch="amd64"
    elif uname -m | grep -q 'i386\|i686'; then
        os_arch="386"
    elif uname -m | grep -q 'aarch64\|armv8b\|armv8l'; then
        os_arch="arm64"
    elif uname -m | grep -q 'arm'; then
        os_arch="arm"
    elif uname -m | grep -q 's390x'; then
        os_arch="s390x"
    elif uname -m | grep -q 'riscv64'; then
        os_arch="riscv64"
    fi

    ## China_IP
    if [ -z "$CN" ]; then
        geo_check
        if [ -n "$isCN" ]; then
            echo "根据geoip api提供的信息，当前IP可能在中国"
            echo -n "是否选用中国镜像完成安装? [Y/n] (自定义镜像输入 3): "
            read -r input
            case $input in
            [yY][eE][sS] | [yY])
                echo "使用中国镜像"
                CN=true
                ;;
            [nN][oO] | [nN])
                echo "不使用中国镜像"
                ;;
            [3])
                echo "使用自定义镜像"
                echo -n "请输入自定义镜像 (例如:dn-dao-github-mirror.daocloud.io) 留空为不使用: "
                read -r input
                case $input in
                    *)
                        CUSTOM_MIRROR=$input
                        ;;
                esac
                ;;
            *)
                echo "使用中国镜像"
                CN=true
                ;;
            esac
        fi
    fi

    if [ -n "$CUSTOM_MIRROR" ]; then
        GITHUB_RAW_URL="gitee.com/naibahq/nezha/raw/master"
        GITHUB_URL=$CUSTOM_MIRROR
        GET_DOCKER_URL="get.docker.com"
        GET_DOCKER_ARG=" -s docker --mirror Aliyun"
        DOCKER_IMG="registry.cn-shanghai.aliyuncs.com\/naibahq\/nezha-dashboard:v0.20.13"
    else
        if [ -z "$CN" ]; then
            GITHUB_RAW_URL="raw.githubusercontent.com/naiba/nezha/master"
            GITHUB_URL="github.com"
            GET_DOCKER_URL="get.docker.com"
            GET_DOCKER_ARG=" "
            DOCKER_IMG="ghcr.io\/naiba\/nezha-dashboard:v0.20.13"
        else
            GITHUB_RAW_URL="gitee.com/naibahq/nezha/raw/master"
            GITHUB_URL="gitee.com"
            GET_DOCKER_URL="get.docker.com"
            GET_DOCKER_ARG=" -s docker --mirror Aliyun"
            DOCKER_IMG="registry.cn-shanghai.aliyuncs.com\/naibahq\/nezha-dashboard:v0.20.13"
        fi
    fi
}

installation_check() {
    if docker compose version >/dev/null 2>&1; then
        DOCKER_COMPOSE_COMMAND="docker compose"
        if sudo $DOCKER_COMPOSE_COMMAND ls | grep -qw "$NZ_DASHBOARD_PATH/docker-compose.yaml" >/dev/null 2>&1; then
            NEZHA_IMAGES=$(sudo docker images --format "{{.Repository}}:{{.Tag}}" | grep -w "nezha-dashboard")
            if [ -n "$NEZHA_IMAGES" ]; then
                echo "存在带有 nezha-dashboard 仓库的 Docker 镜像："
                echo "$NEZHA_IMAGES"
                IS_DOCKER_NEZHA=1
                FRESH_INSTALL=0
                return
            else
                echo "未找到带有 nezha-dashboard 仓库的 Docker 镜像。"
            fi
        fi
    elif command -v docker-compose >/dev/null 2>&1; then
        DOCKER_COMPOSE_COMMAND="docker-compose"
        if sudo $DOCKER_COMPOSE_COMMAND -f "$NZ_DASHBOARD_PATH/docker-compose.yaml" config >/dev/null 2>&1; then
            NEZHA_IMAGES=$(sudo docker images --format "{{.Repository}}:{{.Tag}}" | grep -w "nezha-dashboard")
            if [ -n "$NEZHA_IMAGES" ]; then
                echo "存在带有 nezha-dashboard 仓库的 Docker 镜像："
                echo "$NEZHA_IMAGES"
                IS_DOCKER_NEZHA=1
                FRESH_INSTALL=0
                return
            else
                echo "未找到带有 nezha-dashboard 仓库的 Docker 镜像。"
            fi
        fi
    fi

    if [ -f "$NZ_DASHBOARD_PATH/app" ]; then
        IS_DOCKER_NEZHA=0
        FRESH_INSTALL=0
    fi
}

select_version() {
    if [ -z "$IS_DOCKER_NEZHA" ]; then
        _yellow "请自行选择您的安装方式(如果你是安装Agent，输入哪个都是一样的): "
        _yellow "1. Docker"
        _yellow "2. 独立安装"
        while true; do
            printf "请输入选择 [1-2]:"
            read -r option
            case "${option}" in
                1)
                    IS_DOCKER_NEZHA=1
                    break
                    ;;
                2)
                    IS_DOCKER_NEZHA=0
                    break
                    ;;
                *)
                    _red "请输入正确的选择 [1-2]"
                    ;;
            esac
        done
    fi
}

update_script() {
    echo "> 更新脚本"

    #curl -sL https://${GITHUB_RAW_URL}/script/install.sh -o /tmp/nezha.sh
    #new_version=$(grep "NZ_VERSION" /tmp/nezha.sh | head -n 1 | awk -F "=" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
    #if [ -z "$new_version" ]; then
    #    echo "脚本获取失败，请检查本机能否链接 https://${GITHUB_RAW_URL}/script/install.sh"
    #    return 1
    #fi
    #echo "当前最新版本为: ${new_version}"
    if [ -z "$CN" ]; then
        curl -fsSkL raw.githubusercontent.com/honeok/cross/master/nezha/install.sh -o /tmp/nezha.sh
    else
        curl -fsSkL gh.611611.best/raw.githubusercontent.com/honeok/cross/master/nezha/install.sh -o /tmp/nezha.sh
    fi
    mv -f /tmp/nezha.sh ./nezha.sh && chmod a+x ./nezha.sh

    echo "3s后执行新脚本"
    sleep 3s
    clear
    exec ./nezha.sh
    exit 0
}

before_show_menu() {
    echo && _yellow "* 按回车返回主菜单 *" && read temp
    show_menu
}

install_base() {
    (command -v curl >/dev/null 2>&1 && command -v wget >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1 && command -v getenforce >/dev/null 2>&1) ||
        (install_soft curl wget unzip)
}

install_arch() {
    _yellow "提示：Arch安装libselinux需添加nezha-agent用户，安装完会自动删除，建议手动检查一次"
    read -r -p "是否安装libselinux? [Y/n] " input
    case $input in
    [yY][eE][sS] | [yY])
        useradd -m nezha-agent
        sed -i "$ a\nezha-agent ALL=(ALL ) NOPASSWD:ALL" /etc/sudoers
        sudo -iu nezha-agent bash -c 'gpg --keyserver keys.gnupg.net --recv-keys 4695881C254508D1;
                                        cd /tmp; git clone https://aur.archlinux.org/libsepol.git; cd libsepol; makepkg -si --noconfirm --asdeps; cd ..;
                                        git clone https://aur.archlinux.org/libselinux.git; cd libselinux; makepkg -si --noconfirm; cd ..;
                                        rm -rf libsepol libselinux'
        sed -i '/nezha-agent/d' /etc/sudoers && sleep 30s && killall -u nezha-agent && userdel -r nezha-agent
        echo -e "${red}提示: ${white}已删除用户nezha-agent，请务必手动核查一遍！\n"
        ;;
    [nN][oO] | [nN])
        echo "不安装libselinux"
        ;;
    *)
        echo "不安装libselinux"
        exit 0
        ;;
    esac
}

install_soft() {
    (command -v yum >/dev/null 2>&1 && sudo yum makecache && sudo yum install "$@" selinux-policy -y) ||
    (command -v apt >/dev/null 2>&1 && sudo apt update && sudo apt install "$@" selinux-utils -y) ||
    (command -v pacman >/dev/null 2>&1 && sudo pacman -Syu "$@" base-devel --noconfirm && install_arch) ||
    (command -v apt-get >/dev/null 2>&1 && sudo apt-get update && sudo apt-get install "$@" selinux-utils -y) ||
    (command -v apk >/dev/null 2>&1 && sudo apk update && sudo apk add "$@" -f)
}

install_dashboard() {
    check_systemd
    install_base

    echo "> 安装面板"

    # 哪吒监控文件夹
    if [ ! "$FRESH_INSTALL" = 0 ]; then
        sudo mkdir -p $NZ_DASHBOARD_PATH
    else
        echo "您可能已经安装过面板端，重复安装会覆盖数据，请注意备份。"
        printf "是否退出安装? [Y/n] "
        read -r input
        case $input in
        [yY][eE][sS] | [yY])
            echo "退出安装"
            exit 0
            ;;
        [nN][oO] | [nN])
            echo "继续安装"
            ;;
        *)
            echo "退出安装"
            exit 0
            ;;
        esac
    fi

    if [ "$IS_DOCKER_NEZHA" = 1 ]; then
        install_dashboard_docker
    elif [ "$IS_DOCKER_NEZHA" = 0 ]; then
        install_dashboard_standalone
    fi

    modify_dashboard_config 0

    if [ $# = 0 ]; then
        before_show_menu
    fi
}

install_dashboard_docker() {
    if [ ! "$FRESH_INSTALL" = 0 ]; then
        if ! command -v docker >/dev/null 2>&1; then
            echo "正在安装 Docker"
            if [ "$os_alpine" != 1 ]; then
                if ! curl -sL https://${GET_DOCKER_URL} | sudo bash -s "${GET_DOCKER_ARG}"; then
                    _red "下载脚本失败，请检查本机能否连接 ${GET_DOCKER_URL}"
                    return 0
                fi
                sudo systemctl enable docker.service
                sudo systemctl start docker.service
            else
                sudo apk add docker docker-compose
                sudo rc-update add docker
                sudo rc-service docker start
            fi
            _green "Docker 安装成功"
            installation_check
        fi
    fi
}

install_dashboard_standalone() {
    if [ ! -d "${NZ_DASHBOARD_PATH}/resource/template/theme-custom" ] || [ ! -d "${NZ_DASHBOARD_PATH}/resource/static/custom" ]; then
        sudo mkdir -p "${NZ_DASHBOARD_PATH}/resource/template/theme-custom" "${NZ_DASHBOARD_PATH}/resource/static/custom" >/dev/null 2>&1
    fi
}

selinux() {
    #Check SELinux
    if command -v getenforce >/dev/null 2>&1; then
        if getenforce | grep '[Ee]nfor'; then
            echo "SELinux是开启状态，正在关闭！"
            sudo setenforce 0 >/dev/null 2>&1
            find_key="SELINUX="
            sudo sed -ri "/^$find_key/c${find_key}disabled" /etc/selinux/config
        fi
    fi
}

install_agent() {
    install_base
    selinux

    echo "> 安装监控Agent"

    echo "正在获取监控Agent版本号"

    _version=$(curl -sL "https://api.github.com/repos/nezhahq/agent/releases/tags/v0.20.5" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
    if [ -z "$_version" ]; then
        _version=$(curl -m 10 -sL "https://gitee.com/api/v5/repos/naibahq/agent/tags" | grep -o '"name": *"v0.20.5"' | awk -F '"' '{print $4}')
    fi
    if [ -z "$_version" ]; then
        _version=$(curl -m 10 -sL "https://fastly.jsdelivr.net/gh/nezhahq/agent@v0.20.5/" | grep "option\.value" | awk -F "'" '{print $2}' | sed 's/nezhahq\/agent@/v/g')
    fi
    if [ -z "$_version" ]; then
        _version=$(curl -m 10 -sL "https://gcore.jsdelivr.net/gh/nezhahq/agent@v0.20.5/" | grep "option\.value" | awk -F "'" '{print $2}' | sed 's/nezhahq\/agent@/v/g')
    fi

    if [ -z "$_version" ]; then
        _red "获取版本号失败，请检查本机能否链接 https://api.github.com/repos/nezhahq/agent/releases/tags/v0.20.5"
        return 1
    else
        echo "当前最新版本为: ${_version}"
    fi

    # 哪吒监控文件夹
    sudo mkdir -p $NZ_AGENT_PATH

    echo "正在下载监控端"
    if [ -z "$CN" ]; then
        NZ_AGENT_URL="https://${GITHUB_URL}/nezhahq/agent/releases/download/${_version}/nezha-agent_linux_${os_arch}.zip"
    else
        NZ_AGENT_URL="https://${GITHUB_URL}/naibahq/agent/releases/download/${_version}/nezha-agent_linux_${os_arch}.zip"
    fi

    _cmd="wget -t 2 -T 60 -O nezha-agent_linux_${os_arch}.zip $NZ_AGENT_URL >/dev/null 2>&1"
    if ! eval "$_cmd"; then
        _red "Release 下载失败，请检查本机能否连接 ${GITHUB_URL}"
        return 1
    fi

    sudo unzip -qo nezha-agent_linux_${os_arch}.zip &&
        sudo mv nezha-agent $NZ_AGENT_PATH &&
        sudo rm -rf nezha-agent_linux_${os_arch}.zip README.md

    if [ $# -ge 3 ]; then
        modify_agent_config "$@"
    else
        modify_agent_config 0
    fi

    if [ $# = 0 ]; then
        before_show_menu
    fi
}

modify_agent_config() {
    echo "> 修改Agent配置"

    if [ $# -lt 3 ]; then
        echo "请先在管理面板上添加Agent，记录下密钥"
            printf "请输入一个解析到面板所在IP的域名(不可套CDN): "
            read -r nz_grpc_host
            printf "请输入面板RPC端口 (默认值 5555): "
            read -r nz_grpc_port
            printf "请输入Agent 密钥: "
            read -r nz_client_secret
            printf "是否启用针对 gRPC 端口的 SSL/TLS加密 (--tls)，需要请按 [y]，默认是不需要，不理解用户可回车跳过: "
            read -r nz_grpc_proxy
        echo "${nz_grpc_proxy}" | grep -qiw 'Y' && args='--tls'
        if [ -z "$nz_grpc_host" ] || [ -z "$nz_client_secret" ]; then
            _red "所有选项都不能为空"
            before_show_menu
            return 1
        fi
        if [ -z "$nz_grpc_port" ]; then
            nz_grpc_port=5555
        fi
    else
        nz_grpc_host=$1
        nz_grpc_port=$2
        nz_client_secret=$3
        shift 3
        if [ $# -gt 0 ]; then
            args="$*"
        fi
    fi

    _cmd="sudo ${NZ_AGENT_PATH}/nezha-agent service install -s $nz_grpc_host:$nz_grpc_port -p $nz_client_secret $args >/dev/null 2>&1"

    if ! eval "$_cmd"; then
        sudo "${NZ_AGENT_PATH}"/nezha-agent service uninstall >/dev/null 2>&1
        sudo "${NZ_AGENT_PATH}"/nezha-agent service install -s "$nz_grpc_host:$nz_grpc_port" -p "$nz_client_secret" "$args" >/dev/null 2>&1
    fi
    
    _green "Agent配置 修改成功，请稍等重启生效"

    #if [[ $# == 0 ]]; then
    #    before_show_menu
    #fi
}

modify_dashboard_config() {
    echo "> 修改面板配置"

    if [ "$IS_DOCKER_NEZHA" = 1 ]; then
        if [ -n "$DOCKER_COMPOSE_COMMAND" ]; then
            echo "正在下载 Docker 脚本"
            _cmd="wget -t 2 -T 60 -O /tmp/nezha-docker-compose.yaml https://${GITHUB_RAW_URL}/script/docker-compose.yaml >/dev/null 2>&1"
            if ! eval "$_cmd"; then
                _red "下载脚本失败，请检查本机能否连接 ${GITHUB_RAW_URL}"
                return 0
            fi
        else
            _red "请手动安装 docker-compose。https://docs.docker.com/compose/install/linux/"
            before_show_menu
        fi
    fi

    _cmd="wget -t 2 -T 60 -O /tmp/nezha-config.yaml https://${GITHUB_RAW_URL}/script/config.yaml >/dev/null 2>&1"
    if ! eval "$_cmd"; then
        _red "下载脚本失败，请检查本机能否连接 ${GITHUB_RAW_URL}"
        return 0
    fi

    echo "关于 GitHub Oauth2 应用：在 https://github.com/settings/developers 创建，无需审核，Callback 填 http(s)://域名或IP/oauth2/callback"
    echo "关于 Gitee Oauth2 应用：在 https://gitee.com/oauth/applications 创建，无需审核，Callback 填 http(s)://域名或IP/oauth2/callback"
    printf "请输入 OAuth2 提供商(github/gitlab/jihulab/gitee，默认 github): "
    read -r nz_oauth2_type
    printf "请输入Oauth2应用的 Client ID: "
    read -r nz_github_oauth_client_id
    printf "请输入Oauth2应用的 Client Secret: "
    read -r nz_github_oauth_client_secret
    printf "请输入GitHub/Gitee登录名作为管理员，多个以逗号隔开: "
    read -r nz_admin_logins
    printf "请输入站点标题: "
    read -r nz_site_title
    printf "请输入站点访问端口: (默认 8008)"
    read -r nz_site_port
    printf "请输入用于Agent接入的RPC端口: (默认 5555)"
    read -r nz_grpc_port

    if [ -z "$nz_admin_logins" ] || [ -z "$nz_github_oauth_client_id" ] || [ -z "$nz_github_oauth_client_secret" ] || [ -z "$nz_site_title" ]; then
        _red "所有选项都不能为空"
        before_show_menu
        return 1
    fi

    if [ -z "$nz_site_port" ]; then
        nz_site_port=8008
    fi
    if [ -z "$nz_grpc_port" ]; then
        nz_grpc_port=5555
    fi
    if [ -z "$nz_oauth2_type" ]; then
        nz_oauth2_type=github
    fi

    sed -i "s/nz_oauth2_type/${nz_oauth2_type}/" /tmp/nezha-config.yaml
    sed -i "s/nz_admin_logins/${nz_admin_logins}/" /tmp/nezha-config.yaml
    sed -i "s/nz_grpc_port/${nz_grpc_port}/" /tmp/nezha-config.yaml
    sed -i "s/nz_github_oauth_client_id/${nz_github_oauth_client_id}/" /tmp/nezha-config.yaml
    sed -i "s/nz_github_oauth_client_secret/${nz_github_oauth_client_secret}/" /tmp/nezha-config.yaml
    sed -i "s/nz_language/zh-CN/" /tmp/nezha-config.yaml
    sed -i "s/nz_site_title/${nz_site_title}/" /tmp/nezha-config.yaml
    if [ "$IS_DOCKER_NEZHA" = 1 ]; then
        sed -i "s/nz_site_port/${nz_site_port}/" /tmp/nezha-docker-compose.yaml
        sed -i "s/nz_grpc_port/${nz_grpc_port}/g" /tmp/nezha-docker-compose.yaml
        sed -i "s/nz_image_url/${DOCKER_IMG}/" /tmp/nezha-docker-compose.yaml
    elif [ "$IS_DOCKER_NEZHA" = 0 ]; then
        sed -i "s/80/${nz_site_port}/" /tmp/nezha-config.yaml
    fi

    sudo mkdir -p $NZ_DASHBOARD_PATH/data
    sudo mv -f /tmp/nezha-config.yaml ${NZ_DASHBOARD_PATH}/data/config.yaml
    if [ "$IS_DOCKER_NEZHA" = 1 ]; then
        sudo mv -f /tmp/nezha-docker-compose.yaml ${NZ_DASHBOARD_PATH}/docker-compose.yaml
    fi

    if [ "$IS_DOCKER_NEZHA" = 0 ]; then
        echo "正在下载服务文件"
        if [ "$os_alpine" != 1 ]; then
            _download="sudo wget -t 2 -T 60 -O $NZ_DASHBOARD_SERVICE https://${GITHUB_RAW_URL}/script/nezha-dashboard.service >/dev/null 2>&1"
            if ! eval "$_download"; then
                _red "文件下载失败，请检查本机能否连接 ${GITHUB_RAW_URL}"
                return 0
            fi
        else
            _download="sudo wget -t 2 -T 60 -O $NZ_DASHBOARD_SERVICERC https://${GITHUB_RAW_URL}/script/nezha-dashboard >/dev/null 2>&1"
            if ! eval "$_download"; then
                _red "文件下载失败，请检查本机能否连接 ${GITHUB_RAW_URL}"
                return 0
            fi
            sudo chmod +x $NZ_DASHBOARD_SERVICERC
        fi
    fi

    _green "面板配置 修改成功，请稍等重启生效"

    restart_and_update

    if [ $# = 0 ]; then
        before_show_menu
    fi
}

restart_and_update() {
    echo "> 重启并更新面板"

    if [ "$IS_DOCKER_NEZHA" = 1 ]; then
        _cmd="restart_and_update_docker"
    elif [ "$IS_DOCKER_NEZHA" = 0 ]; then
        _cmd="restart_and_update_standalone"
    fi

    if eval "$_cmd"; then
        _green "哪吒监控 重启成功"
        _yellow "默认管理面板地址：域名:站点访问端口"
    else
        _red "重启失败，可能是因为启动时间超过了两秒，请稍后查看日志信息"
    fi

    if [ $# = 0 ]; then
        before_show_menu
    fi
}

restart_and_update_docker() {
    sudo $DOCKER_COMPOSE_COMMAND -f ${NZ_DASHBOARD_PATH}/docker-compose.yaml pull
    sudo $DOCKER_COMPOSE_COMMAND -f ${NZ_DASHBOARD_PATH}/docker-compose.yaml down
    sudo $DOCKER_COMPOSE_COMMAND -f ${NZ_DASHBOARD_PATH}/docker-compose.yaml up -d
}

restart_and_update_standalone() {
    _version=$(curl -m 10 -sL "https://api.github.com/repos/naiba/nezha/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
    if [ -z "$_version" ]; then
        _version=$(curl -m 10 -sL "https://gitee.com/api/v5/repos/naibahq/nezha/releases/latest" | awk -F '"' '{for(i=1;i<=NF;i++){if($i=="tag_name"){print $(i+2)}}}')
    fi
    if [ -z "$_version" ]; then
        _version=$(curl -m 10 -sL "https://fastly.jsdelivr.net/gh/naiba/nezha/" | grep "option\.value" | awk -F "'" '{print $2}' | sed 's/naiba\/nezha@/v/g')
    fi
    if [ -z "$_version" ]; then
        _version=$(curl -m 10 -sL "https://gcore.jsdelivr.net/gh/naiba/nezha/" | grep "option\.value" | awk -F "'" '{print $2}' | sed 's/naiba\/nezha@/v/g')
    fi

    if [ -z "$_version" ]; then
        _red "获取版本号失败，请检查本机能否链接 https://api.github.com/repos/naiba/nezha/releases/latest"
        return 1
    else
        echo "当前最新版本为: ${_version}"
    fi

    if [ "$os_alpine" != 1 ]; then
        sudo systemctl daemon-reload
        sudo systemctl stop nezha-dashboard
    else
        sudo rc-service nezha-dashboard stop
    fi

    if [ -z "$CN" ]; then
        NZ_DASHBOARD_URL="https://${GITHUB_URL}/naiba/nezha/releases/download/${_version}/dashboard-linux-${os_arch}.zip"
    else
        NZ_DASHBOARD_URL="https://${GITHUB_URL}/naibahq/nezha/releases/download/${_version}/dashboard-linux-${os_arch}.zip"
    fi

    sudo wget -qO $NZ_DASHBOARD_PATH/app.zip "$NZ_DASHBOARD_URL" >/dev/null 2>&1 && sudo unzip -qq -o $NZ_DASHBOARD_PATH/app.zip -d $NZ_DASHBOARD_PATH && sudo mv $NZ_DASHBOARD_PATH/dashboard-linux-$os_arch $NZ_DASHBOARD_PATH/app && sudo rm $NZ_DASHBOARD_PATH/app.zip
    sudo chmod +x $NZ_DASHBOARD_PATH/app

    if [ "$os_alpine" != 1 ]; then
        sudo systemctl enable nezha-dashboard
        sudo systemctl restart nezha-dashboard
    else
        sudo rc-update add nezha-dashboard
        sudo rc-service nezha-dashboard restart
    fi
}

start_dashboard() {
    echo "> 启动面板"

    if [ "$IS_DOCKER_NEZHA" = 1 ]; then
        _cmd="start_dashboard_docker"
    elif [ "$IS_DOCKER_NEZHA" = 0 ]; then
        _cmd="start_dashboard_standalone"
    fi

    if eval "$_cmd"; then
        _green "哪吒监控 启动成功"
    else
        _red "启动失败，请稍后查看日志信息"
    fi

    if [ $# = 0 ]; then
        before_show_menu
    fi
}

start_dashboard_docker() {
    sudo $DOCKER_COMPOSE_COMMAND -f ${NZ_DASHBOARD_PATH}/docker-compose.yaml up -d
}

start_dashboard_standalone() {
    if [ "$os_alpine" != 1 ]; then
        sudo systemctl start nezha-dashboard
    else
        sudo rc-service nezha-dashboard start
    fi
}

stop_dashboard() {
    echo "> 停止面板"

    if [ "$IS_DOCKER_NEZHA" = 1 ]; then
        _cmd="stop_dashboard_docker"
    elif [ "$IS_DOCKER_NEZHA" = 0 ]; then
        _cmd="stop_dashboard_standalone"
    fi

    if eval "$_cmd"; then
        _green "哪吒监控 停止成功"
    else
        _red "停止失败，请稍后查看日志信息"
    fi

    if [ $# = 0 ]; then
        before_show_menu
    fi
}

stop_dashboard_docker() {
    sudo $DOCKER_COMPOSE_COMMAND -f ${NZ_DASHBOARD_PATH}/docker-compose.yaml down
}

stop_dashboard_standalone() {
    if [ "$os_alpine" != 1 ]; then
        sudo systemctl stop nezha-dashboard
    else
        sudo rc-service nezha-dashboard stop
    fi
}

show_dashboard_log() {
    echo "> 获取面板日志"

    if [ "$IS_DOCKER_NEZHA" = 1 ]; then
        show_dashboard_log_docker
    elif [ "$IS_DOCKER_NEZHA" = 0 ]; then
        show_dashboard_log_standalone
    fi

    if [ $# = 0 ]; then
        before_show_menu
    fi
}

show_dashboard_log_docker() {
    sudo $DOCKER_COMPOSE_COMMAND -f ${NZ_DASHBOARD_PATH}/docker-compose.yaml logs -f
}

show_dashboard_log_standalone() {
    if [ "$os_alpine" != 1 ]; then
        sudo journalctl -xf -u nezha-dashboard.service
    else
        sudo tail -n 10 /var/log/nezha-dashboard._red
    fi
}

uninstall_dashboard() {
    echo "> 卸载管理面板"

    if [ "$IS_DOCKER_NEZHA" = 1 ]; then
        uninstall_dashboard_docker
    elif [ "$IS_DOCKER_NEZHA" = 0 ]; then
        uninstall_dashboard_standalone
    fi

    clean_all

    if [ $# = 0 ]; then
        before_show_menu
    fi
}

uninstall_dashboard_docker() {
    sudo $DOCKER_COMPOSE_COMMAND -f ${NZ_DASHBOARD_PATH}/docker-compose.yaml down
    sudo rm -rf $NZ_DASHBOARD_PATH
    sudo docker rmi -f ghcr.io/naiba/nezha-dashboard >/dev/null 2>&1
    sudo docker rmi -f registry.cn-shanghai.aliyuncs.com/naibahq/nezha-dashboard >/dev/null 2>&1
}

uninstall_dashboard_standalone() {
    sudo rm -rf $NZ_DASHBOARD_PATH

    if [ "$os_alpine" != 1 ]; then
        sudo systemctl disable nezha-dashboard
        sudo systemctl stop nezha-dashboard
    else
        sudo rc-update del nezha-dashboard
        sudo rc-service nezha-dashboard stop
    fi

    if [ "$os_alpine" != 1 ]; then
        sudo rm $NZ_DASHBOARD_SERVICE
    else
        sudo rm $NZ_DASHBOARD_SERVICERC
    fi
}

show_agent_log() {
    echo "> 获取Agent日志"

    if [ "$os_alpine" != 1 ]; then
        sudo journalctl -xf -u nezha-agent.service
    else
        sudo tail -n 10 /var/log/nezha-agent._red
    fi

    if [ $# = 0 ]; then
        before_show_menu
    fi
}

uninstall_agent() {
    echo "> 卸载Agent"

    sudo ${NZ_AGENT_PATH}/nezha-agent service uninstall

    sudo rm -rf $NZ_AGENT_PATH
    clean_all

    if [ $# = 0 ]; then
        before_show_menu
    fi
}

restart_agent() {
    echo "> 重启Agent"

    sudo ${NZ_AGENT_PATH}/nezha-agent service restart

    if [ $# = 0 ]; then
        before_show_menu
    fi
}

clean_all() {
    if [ -z "$(ls -A ${NZ_BASE_PATH})" ]; then
        sudo rm -rf ${NZ_BASE_PATH}
    fi
}

show_usage() {
    echo "哪吒监控 管理脚本使用方法: "
    echo "--------------------------------------------------------"
    echo "./nezha.sh                            - 显示管理菜单"
    echo "./nezha.sh install_dashboard          - 安装面板端"
    echo "./nezha.sh modify_dashboard_config    - 修改面板配置"
    echo "./nezha.sh start_dashboard            - 启动面板"
    echo "./nezha.sh stop_dashboard             - 停止面板"
    echo "./nezha.sh restart_and_update         - 重启并更新面板"
    echo "./nezha.sh show_dashboard_log         - 查看面板日志"
    echo "./nezha.sh uninstall_dashboard        - 卸载管理面板"
    echo "--------------------------------------------------------"
    echo "./nezha.sh install_agent              - 安装监控Agent"
    echo "./nezha.sh modify_agent_config        - 修改Agent配置"
    echo "./nezha.sh show_agent_log             - 查看Agent日志"
    echo "./nezha.sh uninstall_agent            - 卸载Agen"
    echo "./nezha.sh restart_agent              - 重启Agen"
    echo "./nezha.sh update_script              - 更新脚本"
    echo "--------------------------------------------------------"
}

show_menu() {
    clear
    echo -e "${green}哪吒监控管理脚本${white} ${cyan}${NZ_VERSION}${white}"
    echo "https://github.com/nezhahq/nezha"
    echo -e "Modified By: honeok ${SCRIPT_v}"
    echo "------------------------"
    echo -e "${green}1.${white}  安装面板端"
    echo -e "${green}2.${white}  修改面板配置"
    echo -e "${green}3.${white}  启动面板"
    echo -e "${green}4.${white}  停止面板"
    echo -e "${green}5.${white}  重启并更新面板"
    echo -e "${green}6.${white}  查看面板日志"
    echo -e "${green}7.${white}  卸载管理面板"
    echo "------------------------"
    echo -e "${green}8.${white}  安装监控Agent"
    echo -e "${green}9.${white}  修改Agent配置"
    echo -e "${green}10.${white} 查看Agent日志"
    echo -e "${green}11.${white} 卸载Agent"
    echo -e "${green}12.${white} 重启Agent"
    echo "------------------------"
    echo -e "${green}13.${white} 更新脚本"
    echo "------------------------"
    echo -e "${green}0.${white}  退出脚本"

    echo -n "请输入选择 [0-13]: "
    read -r num
    case "${num}" in
        1)
            install_dashboard
            ;;
        2)
            modify_dashboard_config
            ;;
        3)
            start_dashboard
            ;;
        4)
            stop_dashboard
            ;;
        5)
            restart_and_update
            ;;
        6)
            show_dashboard_log
            ;;
        7)
            uninstall_dashboard
            ;;
        8)
            install_agent
            ;;
        9)
            modify_agent_config
            ;;
        10)
            show_agent_log
            ;;
        11)
            uninstall_agent
            ;;
        12)
            restart_agent
            ;;
        13)
            update_script
            ;;
        0)
            exit 0
            ;;
        *)
            _red "请输入正确的数字 [0-13]"
            ;;
    esac
}

pre_check
installation_check

if [ $# -gt 0 ]; then
    case $1 in
        "install_dashboard")
            install_dashboard 0
            ;;
        "modify_dashboard_config")
            modify_dashboard_config 0
            ;;
        "start_dashboard")
            start_dashboard 0
            ;;
        "stop_dashboard")
            stop_dashboard 0
            ;;
        "restart_and_update")
            restart_and_update 0
            ;;
        "show_dashboard_log")
            show_dashboard_log 0
            ;;
        "uninstall_dashboard")
            uninstall_dashboard 0
            ;;
        "install_agent")
            shift
            if [ $# -ge 3 ]; then
                install_agent "$@"
            else
                install_agent 0
            fi
            ;;
        "modify_agent_config")
            modify_agent_config 0
            ;;
        "show_agent_log")
            show_agent_log 0
            ;;
        "uninstall_agent")
            uninstall_agent 0
            ;;
        "restart_agent")
            restart_agent 0
            ;;
        "update_script")
            update_script 0
            ;;
        *) show_usage ;;
    esac
else
    select_version
    show_menu
fi