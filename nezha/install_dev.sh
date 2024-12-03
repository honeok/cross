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
NZ_VERSION="v0"
GH_PROXY="https://gh-proxy.com/"
SCRIPT_V="2024.12.01"

yellow='\033[93m'
red='\033[31m'
green='\033[92m'
cyan='\033[96m'
purple='\033[95m'
white='\033[0m'
_yellow() { echo -e ${yellow}$@${white}; }
_red() { echo -e ${red}$@${white}; }
_green() { echo -e ${green}$@${white}; }
_cyan() { echo -e ${cyan}$@${white}; }
_purple() { echo -e ${purple}$@${white}; }

export PATH="$PATH:/usr/local/bin"

os_arch=""
[ -e /etc/os-release ] && grep -i '^PRETTY_NAME=' /etc/*release | grep -qi "alpine" && os_alpine='1'

ip_address() {
    local ipv4_services=("ipv4.ip.sb" "ipv4.icanhazip.com" "v4.ident.me" "api.ipify.org")
    local ipv6_services=("ipv6.ip.sb" "ipv6.icanhazip.com" "v6.ident.me" "api6.ipify.org")

    ipv4_address=""
    ipv6_address=""

    for service in "${ipv4_services[@]}"; do
        ipv4_address=$(curl -fskL4 -m 3 "$service")
        if [[ "$ipv4_address" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            break
        fi
    done

    for service in "${ipv6_services[@]}"; do
        ipv6_address=$(curl -fskL6 -m 3 "$service")
        if [[ "$ipv6_address" =~ ^[0-9a-fA-F:]+$ ]]; then
            break
        fi
    done
}

# 根据用户权限决定是否使用sudo
sudo() {
    if [ "$(id -ru)" -ne 0 ]; then
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

prepare_check() {
    umask 077

    ## os_arch
    case "$(uname -m)" in
        x86_64) os_arch="amd64" ;;
        i386|i686) os_arch="386" ;;
        aarch64|armv8b|armv8l) os_arch="arm64" ;;
        arm) os_arch="arm" ;;
        s390x) os_arch="s390x" ;;
        riscv64) os_arch="riscv64" ;;
    esac

    ## China_IP
    if [ -z "$CN" ]; then
        geo_check
        if [ -n "$isCN" ]; then
            echo "根据Geoip api提供的信息，当前IP可能在中国"
            echo -n "是否选用中国镜像完成安装? [Y/n]: "
            read -r input
            case $input in
            [yY][eE][sS] | [yY])
                _yellow "使用中国镜像"
                CN=true
                ;;
            [nN][oO] | [nN])
                _yellow "不使用中国镜像"
                ;;
            *)
                _yellow "使用中国镜像"
                CN=true
                ;;
            esac
        fi
    fi

    ip_address

    # 设置GITHUB代理
    if [ -n "$CN" ] || { [ -z "$ipv4_address" ] && [ -n "$ipv6_address" ]; }; then
        GITHUB_PROXY="${GH_PROXY}"
    else
        GITHUB_PROXY=""
    fi

    GITHUB_RAW_URL="${GITHUB_PROXY}raw.githubusercontent.com/honeok/cross/master/nezha"
    GITHUB_URL="github.com"

    if [ -z "$CN" ]; then
        GET_DOCKER_URL="get.docker.com"
        GET_DOCKER_ARG=" "
        DOCKER_IMG="ghcr.io\/naiba\/nezha-dashboard:v0.20.13"
    else
        GET_DOCKER_URL="${GITHUB_PROXY}raw.githubusercontent.com/honeok/Tools/master/docker/install.sh"
        GET_DOCKER_ARG=" -s docker --mirror Aliyun"
        DOCKER_IMG="registry.cn-shanghai.aliyuncs.com\/naibahq\/nezha-dashboard:v0.20.13"
    fi
}

# 检查是否安装nezha-dashboard镜像以及是否已经配置docker-compose
install_check() {
    if docker compose version >/dev/null 2>&1; then
        DOCKER_COMPOSE_COMMAND="docker compose"
        if sudo $DOCKER_COMPOSE_COMMAND ls | grep -qw "$NZ_DASHBOARD_PATH/docker-compose.yaml" >/dev/null 2>&1; then
            NEZHA_IMAGES=$(sudo docker images --format "{{.Repository}}:{{.Tag}}" | grep -w "nezha-dashboard")
            if [ -n "$NEZHA_IMAGES" ]; then
                _green "存在带有nezha-dashboard仓库的Docker镜像: "
                echo "$NEZHA_IMAGES"
                IS_DOCKER_NEZHA=1
                FRESH_INSTALL=0
                return
            else
                _yellow "未找到带有nezha-dashboard仓库的Docker镜像"
            fi
        fi
    elif command -v docker-compose >/dev/null 2>&1; then
        DOCKER_COMPOSE_COMMAND="docker-compose"
        if sudo $DOCKER_COMPOSE_COMMAND -f "$NZ_DASHBOARD_PATH/docker-compose.yaml" config >/dev/null 2>&1; then
            NEZHA_IMAGES=$(sudo docker images --format "{{.Repository}}:{{.Tag}}" | grep -w "nezha-dashboard")
            if [ -n "$NEZHA_IMAGES" ]; then
                _green "存在带有nezha-dashboard仓库的Docker镜像: "
                echo "$NEZHA_IMAGES"
                IS_DOCKER_NEZHA=1
                FRESH_INSTALL=0
                return
            else
                _yellow "未找到带有nezha-dashboard仓库的Docker镜像"
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
            echo -n "请输入选择 [1-2]: "
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

    curl -fskL ${GITHUB_PROXY}raw.githubusercontent.com/honeok/cross/master/nezha/install.sh -o /tmp/nezha.sh
    mv -f /tmp/nezha.sh ./nezha.sh && chmod a+x ./nezha.sh

    _yellow "3s后执行新脚本"
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
    echo -e "${red}提示: ${white}Arch安装libselinux需添加nezha-agent用户，安装完会自动删除建议手动检查一次"
    echo -n -e "${yellow}是否安装libselinux? [Y/n] ${white}"
    read -r input
    case $input in
    [yY][eE][sS] | [yY])
        useradd -m nezha-agent
        sed -i "$ a\nezha-agent ALL=(ALL ) NOPASSWD:ALL" /etc/sudoers
        sudo -iu nezha-agent bash -c 'gpg --keyserver keys.gnupg.net --recv-keys 4695881C254508D1;
                                        cd /tmp; git clone https://aur.archlinux.org/libsepol.git; cd libsepol; makepkg -si --noconfirm --asdeps; cd ..;
                                        git clone https://aur.archlinux.org/libselinux.git; cd libselinux; makepkg -si --noconfirm; cd ..;
                                        rm -fr libsepol libselinux'
        sed -i '/nezha-agent/d' /etc/sudoers && sleep 30s && killall -u nezha-agent && userdel -r nezha-agent
        echo -e "${red}提示: ${white}已删除用户nezha-agent，请务必手动核查一遍！\n"
        ;;
    [nN][oO] | [nN])
        _yellow "不安装libselinux"
        ;;
    *)
        _yellow "不安装libselinux"
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
        echo -e "${red}提示: ${white}您可能已经安装过面板端，重复安装会覆盖数据请注意备份。"
        echo -n  "是否退出安装? [Y/n] "
        read -r input
        case $input in
        [yY][eE][sS] | [yY])
            _yellow "退出安装"
            exit 0
            ;;
        [nN][oO] | [nN])
            _yellow "继续安装"
            ;;
        *)
            _yellow "退出安装"
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
            _yellow "正在安装Docker"
            if [ "$os_alpine" != 1 ]; then
                if ! curl -fskL https://${GET_DOCKER_URL} | sudo bash -s "${GET_DOCKER_ARG}"; then
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
            _green "Docker安装成功"
            install_check
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
            _yellow "SELinux是开启状态，正在关闭！"
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

    _version="v0.20.5"

    # 哪吒监控文件夹
    sudo mkdir -p $NZ_AGENT_PATH

    _yellow "正在下载监控端"
    if [ -z "$CN" ] || { [ -z "$ipv4_address" ] && [ -n "$ipv6_address" ]; }; then
        NZ_AGENT_URL="https://${GITHUB_URL}/nezhahq/agent/releases/download/${_version}/nezha-agent_linux_${os_arch}.zip"
    else
        NZ_AGENT_URL="${GITHUB_PROXY}https://${GITHUB_URL}/naibahq/agent/releases/download/${_version}/nezha-agent_linux_${os_arch}.zip"
    fi

    _cmd="wget -t 2 -T 60 -O nezha-agent_linux_${os_arch}.zip $NZ_AGENT_URL >/dev/null 2>&1"
    if ! eval "$_cmd"; then
        _red "Release下载失败，请检查本机能否连接 ${GITHUB_URL}"
        return 1
    fi

    sudo unzip -qo nezha-agent_linux_${os_arch}.zip &&
    sudo mv nezha-agent $NZ_AGENT_PATH &&
    sudo rm -fr nezha-agent_linux_${os_arch}.zip README.md

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
        _yellow "请先在管理面板上添加Agent，记录下密钥"
        echo -n "请输入一个解析到面板所在IP的域名(不可套CDN): "
        read -r nz_grpc_host
        echo -n "请输入面板RPC端口 (默认值 5555): "
        read -r nz_grpc_port
        echo -n "请输入Agent 密钥: "
        read -r nz_client_secret

        echo -n "是否启用针对gRPC端口的SSL/TLS加密 (--tls)，需要请按 [y]，默认是不需要，不理解用户可回车跳过: "
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

    _green "Agent配置修改成功，请稍等Agent重启生效"

    #if [[ $# == 0 ]]; then
    #    before_show_menu
    #fi
}

modify_dashboard_config() {
    echo "> 修改Dashboard配置"

    if [ "$IS_DOCKER_NEZHA" = 1 ]; then
        if [ -n "$DOCKER_COMPOSE_COMMAND" ]; then
            _yellow "正在下载Docker脚本"
            _cmd="wget -t 2 -T 60 -O /tmp/nezha-docker-compose.yaml https://${GITHUB_RAW_URL}/docker-compose.yaml >/dev/null 2>&1"
            if ! eval "$_cmd"; then
                _red "下载脚本失败，请检查本机能否连接 ${GITHUB_RAW_URL}"
                return 0
            fi
        else
            _red "请手动安装docker-compose https://docs.docker.com/compose/install/linux/"
            before_show_menu
        fi
    fi

    _cmd="wget -t 2 -T 60 -O /tmp/nezha-config.yaml https://${GITHUB_RAW_URL}/config.yaml >/dev/null 2>&1"
    if ! eval "$_cmd"; then
        _red "下载脚本失败，请检查本机能否连接 ${GITHUB_RAW_URL}"
        return 0
    fi

    echo "关于 GitHub Oauth2 应用：在 https://github.com/settings/developers 创建，无需审核，Callback 填 http(s)://域名或IP/oauth2/callback"
    echo "关于 Gitee Oauth2 应用：在 https://gitee.com/oauth/applications 创建，无需审核，Callback 填 http(s)://域名或IP/oauth2/callback"
    echo -n "请输入 OAuth2 提供商(github/gitlab/jihulab/gitee，默认 github): "
    read -r nz_oauth2_type
    echo -n "请输入Oauth2应用的 Client ID: "
    read -r nz_github_oauth_client_id
    echo -n "请输入Oauth2应用的 Client Secret: "
    read -r nz_github_oauth_client_secret
    echo -n "请输入GitHub/Gitee登录名作为管理员，多个以逗号隔开: "
    read -r nz_admin_logins
    echo -n "请输入站点标题: "
    read -r nz_site_title
    echo -n "请输入站点访问端口: (默认 8008)"
    read -r nz_site_port
    echo -n "请输入用于Agent接入的RPC端口: (默认 5555)"
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
        _yellow "正在下载服务文件"
        if [ "$os_alpine" != 1 ]; then
            _download="sudo wget -t 2 -T 60 -O $NZ_DASHBOARD_SERVICE https://${GITHUB_RAW_URL}/nezha-dashboard.service >/dev/null 2>&1"
            if ! eval "$_download"; then
                _red "文件下载失败，请检查本机能否连接 ${GITHUB_RAW_URL}"
                return 0
            fi
        else
            _download="sudo wget -t 2 -T 60 -O $NZ_DASHBOARD_SERVICERC https://${GITHUB_RAW_URL}/nezha-dashboard >/dev/null 2>&1"
            if ! eval "$_download"; then
                _red "文件下载失败，请检查本机能否连接 ${GITHUB_RAW_URL}"
                return 0
            fi
            sudo chmod +x $NZ_DASHBOARD_SERVICERC
        fi
    fi

    _green "Dashboard配置修改成功，请稍等Dashboard重启生效"

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
        _green "哪吒监控重启成功"
        _yellow "默认管理面板地址: 域名:站点访问端口"
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
    _version="v0.20.13"

    if [ -z "$_version" ]; then
        _red "获取Dashboard版本号失败，请检查本机能否链接 https://api.github.com/repos/naiba/nezha/releases/tags/v0.20.13"
        return 1
    else
        echo -e "${yellow}当前最新版本为:${white} ${_version}"
    fi

    if [ "$os_alpine" != 1 ]; then
        sudo systemctl daemon-reload
        sudo systemctl stop nezha-dashboard
    else
        sudo rc-service nezha-dashboard stop
    fi

    if [ -z "$CN" ] || { [ -z "$ipv4_address" ] && [ -n "$ipv6_address" ]; }; then
        NZ_DASHBOARD_URL="https://${GITHUB_URL}/naibahq/nezha/releases/download/${_version}/dashboard-linux-${os_arch}.zip"
    else
        NZ_DASHBOARD_URL="${GITHUB_PROXY}https://${GITHUB_URL}/naibahq/nezha/releases/download/${_version}/dashboard-linux-${os_arch}.zip"
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
    echo "> 获取Dashboard日志"

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
        sudo tail -n 10 /var/log/nezha-dashboard.err
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
    sudo rm -fr $NZ_DASHBOARD_PATH
    #sudo docker rmi -f ghcr.io/naiba/nezha-dashboard >/dev/null 2>&1
    #sudo docker rmi -f registry.cn-shanghai.aliyuncs.com/naibahq/nezha-dashboard >/dev/null 2>&1

    # 删除所有与nezha-dashboard相关的镜像
    for image in $(sudo docker images --format '{{.Repository}}:{{.Tag}}' | grep 'nezha-dashboard'); do
        sudo docker rmi -f $image >/dev/null 2>&1
    done
}

uninstall_dashboard_standalone() {
    sudo rm -fr $NZ_DASHBOARD_PATH

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
        sudo tail -n 10 /var/log/nezha-agent.err
    fi

    if [ $# = 0 ]; then
        before_show_menu
    fi
}

uninstall_agent() {
    echo "> 卸载Agent"

    sudo ${NZ_AGENT_PATH}/nezha-agent service uninstall

    sudo rm -fr $NZ_AGENT_PATH
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
        sudo rm -fr ${NZ_BASE_PATH}
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
    echo -e "-- ${green}哪吒监控管理脚本${purple}${NZ_VERSION}${white}${white} --"
    echo "https://github.com/nezhahq/nezha"
    echo -e "${red}提示: ${white}v0面板停止维护 https://nezha.wiki"
    echo -e "${yellow}v0面板脚本修改版${white} by: honeok"
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
    echo ""
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

prepare_check
install_check

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