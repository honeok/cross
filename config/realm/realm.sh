#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0
#
# Description: The script is an automated one-click deploy tool for install and configuring the realm proxy.
# Copyright (c) 2026 honeok <i@honeok.com>
#
# References:
# https://www.nodeseek.com/post-179931-1
# https://coka.uk/index.php/archives/10/#cl-1

set -eE

# MAJOR.MINOR.PATCH
readonly SCRIPT_VERSION='v1.1.1'

_red() {
    printf "\033[31m%b\033[0m\n" "$*"
}

_green() {
    printf "\033[32m%b\033[0m\n" "$*"
}

_yellow() {
    printf "\033[33m%b\033[0m\n" "$*"
}

_cyan() {
    printf "\033[36m%b\033[0m\n" "$*"
}

_err_msg() {
    printf "\033[41m\033[1mError\033[0m %b\n" "$*"
}

_italic() {
    printf "\033[3m%b\033[23m\n" "$*"
}

# 各变量默认值
TEMP_DIR="$(mktemp -d 2> /dev/null)"
GITHUB_PROXYS=('' 'https://github.akams.cn/' 'https://v6.gh-proxy.org/' 'https://hub.glowp.xyz/' 'https://proxy.vvvv.ee/')

: "${GITHUB_REPO:="zhboner/realm"}"
: "${PROJECT_NAME:="${GITHUB_REPO##*/}"}"
: "${REALM_CONFDIR:="/etc/$PROJECT_NAME"}"
: "${REALM_CONFIG:="$REALM_CONFDIR/realm.toml"}"

# 终止信号捕获
trap 'rm -rf "${TEMP_DIR:?}" > /dev/null 2>&1' INT TERM EXIT

clear() {
    [ -t 1 ] && tput clear 2> /dev/null || printf "\033[2J\033[H" || command clear
}

die() {
    _err_msg >&2 "$(_red "$@")"
    exit 1
}

cd "$TEMP_DIR" > /dev/null 2>&1 || die "Unable to enter the work path."

curl() {
    local RC

    # 添加 --fail 不然404退出码也为0
    # 32位cygwin已停止更新, 证书可能有问题, 添加 --insecure
    # centos7 curl 不支持 --retry-connrefused --retry-all-errors 因此手动 retry
    for ((i = 1; i <= 5; i++)); do
        command curl --connect-timeout 10 --fail --insecure "$@"
        RC="$?"
        if [ "$RC" -eq 0 ]; then
            return
        else
            # 403 404 错误或达到重试次数
            if [ "$RC" -eq 22 ] || [ "$i" -eq 5 ]; then
                return "$RC"
            fi
            sleep 0.5
        fi
    done
}

is_darwin() {
    [ "$(uname -s 2> /dev/null)" = "Darwin" ]
}

is_linux() {
    [ "$(uname -s 2> /dev/null)" = "Linux" ]
}

print_msg() {
    _before() {
        clear
        _italic "$(_cyan "Script Version: $SCRIPT_VERSION")"
    }

    _after() {
        printf "\n"
        printf "%s %s\n" "$(_yellow "$(_italic "Configuration File Path:")")" "$(_italic "$REALM_CONFIG")"
        _green "$(_italic "Realm has been install and started success.")"
    }

    case "$1" in
    before) _before ;;
    after) _after ;;
    esac
}

# 生成随机端口号
random_port() {
    local EXIST_PORT TEMP_PORT PORT

    EXIST_PORT="$(ss -lnptu | sed -n 's/.*:\([0-9]\+\).*/\1/p' | sort -nu)"
    for ((i = 1; i <= 5; i++)); do
        TEMP_PORT="$(shuf -i 20000-65535 -n 1)"
        if ! grep -q "^$TEMP_PORT$" <<< "$EXIST_PORT"; then
            PORT="$TEMP_PORT"
            echo "$PORT"
            break
        fi
    done
    [ -n "$PORT" ] || die "Failed generate random port."
}

# 检测是否为 Glibc 系统
is_glibc() {
    if ldd --version 2>&1 | grep -iq "glibc"; then
        return
    elif getconf GNU_LIBC_VERSION > /dev/null 2>&1; then
        return
    elif [ -n "$(ls /lib/ld-linux* 2> /dev/null)" ] || [ -n "$(ls /lib64/ld-linux* 2> /dev/null)" ]; then
        return
    else
        return 1
    fi
}

# 检测是否需要启用 Github CDN 如能直接连通则不使用
check_cdn() {
    # GITHUB_PROXYS 数组第一个元素为空相当于直连
    local CHECK_URL STATUS_CODE

    for PROXY_URL in "${GITHUB_PROXYS[@]}"; do
        CHECK_URL="${PROXY_URL}https://github.com/honeok/cross/raw/master/README.md"
        STATUS_CODE="$(command curl --connect-timeout 3 --fail --insecure -L --output /dev/null --write-out "%{http_code}" "$CHECK_URL")"
        [ "$STATUS_CODE" = "200" ] && GITHUB_PROXY="$PROXY_URL" && break
    done
}

check_sys() {
    if is_linux; then
        OS_NAME="linux"
    elif is_darwin; then
        OS_NAME="darwin"
    else
        die "System is not supported."
    fi
}

check_arch() {
    if is_linux; then
        case "$(uname -m 2> /dev/null || arch 2> /dev/null)" in
        x86_64) OS_ARCH="x86_64" ;;
        aarch64) OS_ARCH="aarch64" ;;
        *) die "Architecture is not supported." ;;
        esac
    elif is_darwin; then
        case "$(uname -m 2> /dev/null || arch 2> /dev/null)" in
        x86_64) OS_ARCH="x86_64" ;;
        aarch64) OS_ARCH="aarch64" ;;
        *) die "Architecture is not supported." ;;
        esac
    else
        die "Architecture is not supported."
    fi
}

# 安装主程序
install_realm() {
    local VERSION GLIBC

    VERSION="$(curl -Ls "${GITHUB_PROXY}https://api.github.com/repos/$GITHUB_REPO/releases" | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' | sort -rV | head -n 1)"
    _yellow "$(_italic "Download realm: $VERSION")"

    if is_glibc; then
        GLIBC="gnu"
    else
        GLIBC="musl"
    fi

    curl -L -O "${GITHUB_PROXY}https://github.com/$GITHUB_REPO/releases/download/v$VERSION/$PROJECT_NAME-$OS_ARCH-unknown-$OS_NAME-$GLIBC.tar.gz"
    tar fx "$PROJECT_NAME-$OS_ARCH-unknown-$OS_NAME-$GLIBC.tar.gz" -C /usr/local/bin
}

# 生成配置文件
gen_cfg() {
    _yellow "$(_italic "Generate config")"
    mkdir -p "$REALM_CONFDIR" > /dev/null 2>&1 || die "Unable to create directory."

    tee "/etc/systemd/system/$PROJECT_NAME.service" > /dev/null << EOF
[Unit]
Description=Realm Proxy Service
Documentation=https://github.com/$GITHUB_REPO
Wants=network-online.target systemd-networkd-wait-online.service
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/realm -c $REALM_CONFIG
Restart=on-failure
RestartSec=5s
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

    tee "$REALM_CONFIG" > /dev/null << EOF
[log]
level = "off"
output = "/dev/null"

[network]
no_tcp = false
use_udp = true
zero_copy = true

# Local -> Remote
[[endpoints]]
listen = "[::]:$(random_port)"
remote = "151.101.1.1:443"
EOF
}

run_realm() {
    systemctl daemon-reload > /dev/null 2>&1
    systemctl enable --now "$PROJECT_NAME.service"
}

print_msg before
check_cdn
check_sys
check_arch
install_realm
gen_cfg
run_realm
print_msg after
