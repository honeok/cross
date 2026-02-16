#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0
#
# Description: The script is used to automate the installation and setup process of a Shadowsocks-Rust service environment.
# Copyright (c) 2026 honeok <i@honeok.com>
#
# References:
# https://github.com/shadowsocks/shadowsocks-rust
# https://www.cdoblog.com/archives/100
# https://skyao.net/learning-debian/docs/network/shadowsocks-rust

set -eE

# MAJOR.MINOR.PATCH
# shellcheck disable=SC2034
readonly SCRIPT_VERSION='v1.0.0'

# 各变量默认值
TEMP_DIR="$(mktemp -d)"
PROJECT_NAME="shadowsocks"
CORE_NAME="$PROJECT_NAME-rust"
CORE_DIR="/etc/$CORE_NAME"

# 终止信号捕获
trap 'rm -rf "${TEMP_DIR:?}" > /dev/null 2>&1' INT TERM EXIT

# 分隔符
separator() {
    local LENGTH="${1:-15}"
    printf "%-${LENGTH}s\n" "-" | sed 's/\s/-/g'
}

clear() {
    [ -t 1 ] && tput clear 2> /dev/null || printf "\033[2J\033[H" || command clear
}

die() {
    echo >&2 "Error: $*"
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

is_alpine() {
    [ -f /etc/alpine-release ]
}

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

random_char() {
    local LENGTH="$1"
    local RANDOM_STRING

    RANDOM_STRING="$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w "$LENGTH" | head -n1)"
    echo "$RANDOM_STRING"
}

get_ip() {
    local PUBLIC_IP

    [ -n "$PUBLIC_IP" ] || PUBLIC_IP="$(curl -Ls -4 http://www.qualcomm.cn/cdn-cgi/trace | grep '^ip=' | cut -d= -f2 | grep .)"
    [ -n "$PUBLIC_IP" ] || PUBLIC_IP="$(curl -Ls -4 ip.sb 2>&1)"
    echo "$PUBLIC_IP"
}

install_ss() {
    local OS_ARCH GLIBC
    local -a FILENAMES

    [ -n "$VERSION" ] || VERSION="$(curl -Ls https://api.github.com/repos/$PROJECT_NAME/$CORE_NAME/releases | grep -m1 '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/')"

    case "$(uname -m 2> /dev/null)" in
    amd64 | x86_64) OS_ARCH="x86_64" ;;
    arm64 | armv8* | aarch64) OS_ARCH="aarch64" ;;
    *) die "unsupported cpu architecture." ;;
    esac

    if is_alpine; then
        GLIBC="musl"
    else
        GLIBC="gnu"
    fi

    FILENAMES=("$PROJECT_NAME-v$VERSION.$OS_ARCH-unknown-linux-$GLIBC.tar.xz" "$PROJECT_NAME-v$VERSION.$OS_ARCH-unknown-linux-$GLIBC.tar.xz.sha256")
    for f in "${FILENAMES[@]}"; do
        curl -Ls -O "https://github.com/$PROJECT_NAME/$CORE_NAME/releases/download/v$VERSION/$f"
    done
    sha256sum -c "$PROJECT_NAME-v$VERSION.$OS_ARCH-unknown-linux-$GLIBC.tar.xz.sha256" > /dev/null 2>&1 || die "checksum verification failed."
    tar fJx "$PROJECT_NAME-v$VERSION.$OS_ARCH-unknown-linux-$GLIBC.tar.xz"
    chmod +x ss*
    mv -f ss* /usr/local/bin
}

gen_cfg() {
    local SERVER_PORT PASSWORD METHOD IP

    mkdir -p "$CORE_DIR" || die "Unable to create directory."

    SERVER_PORT="$(random_port)" # 生成随机端口
    PASSWORD="$(random_char 25)"
    METHOD="chacha20-ietf-poly1305"
    IP="$(get_ip)"

    tee > "$CORE_DIR/config.json" <<- EOF
{
  "server": "::",
  "server_port": $SERVER_PORT,
  "password": "$PASSWORD",
  "timeout": 300,
  "method": "$METHOD",
  "mode": "tcp_and_udp"
}
EOF

    echo "$(separator 9) $CORE_NAME $(separator 8)"
    printf "%-15s: %s\n" "Protocol" "$PROJECT_NAME"
    printf "%-15s: %s\n" "Address" "$IP"
    printf "%-15s: %s\n" "Port" "$SERVER_PORT"
    printf "%-15s: %s\n" "Password" "$PASSWORD"
    printf "%-15s: %s\n" "Encryption" "$METHOD"
    echo "$(separator) URL $(separator)"
    echo "ss://$(printf '%s:%s' "$METHOD" "$PASSWORD" | base64 | tr -d '\n')@$IP:$SERVER_PORT#$PROJECT_NAME-honeok"
    echo "$(separator) URL $(separator)"
}

install_svc() {
    tee > /etc/systemd/system/$PROJECT_NAME.service <<- EOF
[Unit]
Description=Shadowsocks-rust Server Service
Documentation=https://github.com/$PROJECT_NAME/$CORE_NAME
After=network.target

[Service]
Type=simple
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
DynamicUser=yes
ExecStart=/usr/local/bin/ssservice server --log-without-time -c $CORE_DIR/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable --now "$PROJECT_NAME.service"
}

clear
install_ss
gen_cfg
install_svc
