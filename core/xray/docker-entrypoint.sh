#!/usr/bin/env sh
#
# Description: This script is used to configure xray during container initialization.
#
# Copyright (c) 2025 honeok <honeok@disroot.org>
#
# References:
# https://github.com/233boy/Xray
#
# SPDX-License-Identifier: GPL-2.0-only

set -eu

XRAY_WORKDIR="/etc/xray"
XRAY_CONFDIR="$XRAY_WORKDIR/conf"
XRAY_LOGDIR="/var/log/xray"
XRAY_LOGFILE="$XRAY_LOGDIR/access.log"
CLOUDFLARE_API="www.qualcomm.cn"
PUBLIC_IP=$(curl -fsL -m 5 -4 "http://$CLOUDFLARE_API/cdn-cgi/trace" 2>/dev/null | grep -i '^ip=' | cut -d'=' -f2 | grep . || \
            curl -fsL -m 5 -6 "http://$CLOUDFLARE_API/cdn-cgi/trace" 2>/dev/null | grep -i '^ip=' | cut -d'=' -f2 | grep .)

_is_exists() {
    _CMD="$1"
    if type "$_CMD" >/dev/null 2>&1; then return 0;
    elif command -v "$_CMD" >/dev/null 2>&1; then return 0;
    elif which "$_CMD" >/dev/null 2>&1; then return 0;
    else return 1;
    fi
}

# generate random port
random_port() {
    _use_port() {
        if [ -z "${IS_USED_PORT+x}" ]; then
            if _is_exists netstat; then IS_USED_PORT="$(netstat -tunlp | sed -n 's/.*:\([0-9]\+\).*/\1/p' | sort -nu)";
            elif _is_exists ss; then IS_USED_PORT="$(ss -tunlp | sed -n 's/.*:\([0-9]\+\).*/\1/p' | sort -nu)";
            else printf 'Error: The netstat and ss commands are unavailable.\n'; exit 1
            fi
        fi
        printf "%s" "$IS_USED_PORT" | sed 's/ /\n/g' | grep -w "$1"
        return
    }
    PORT=1
    while [ "$PORT" -le 5 ]; do
        TEMP_PORT=$(shuf -i 20000-50000 -n 1)
        if [ ! "$(_use_port "$TEMP_PORT")" ]; then
            REALITY_PORT="$TEMP_PORT" && break
        fi
        [ "$PORT" -eq 5 ] && { printf 'Error: No free port found after 5 attempts.\n'; exit 1; }
        PORT=$((PORT + 1))
    done
}

[ ! -s "$XRAY_WORKDIR/config.json" ] && cat /opt/config.json > "$XRAY_WORKDIR/config.json"

if [ -d "$XRAY_CONFDIR" ] && [ -z "$(ls -A "$XRAY_CONFDIR" 2>/dev/null)" ]; then
    # https://github.com/XTLS/Xray-core/issues/2005
    TLS_SERVERS="www.icloud.com apps.apple.com music.apple.com icloud.cdn-apple.com updates.cdn-apple.com"
    random_port
    GENERATE_UUID=$(xray uuid || cat /proc/sys/kernel/random/uuid)
    GENERATE_KEYS=$(xray x25519)
    PRIVATE_KEY=$(printf "%s" "$GENERATE_KEYS" | sed -n 's/^Private key: *\(.*\)$/\1/p')
    PUBLIC_KEY=$(printf "%s" "$GENERATE_KEYS" | sed -n 's/^Public key: *\(.*\)$/\1/p')
    TLS_SERVER=$(printf "%s" "$TLS_SERVERS" | tr " " "\n" | shuf -n 1)
    cat > "$XRAY_CONFDIR/VLESS-REALITY-$REALITY_PORT.json" <<EOF
{
  "inbounds": [
    {
      "tag": "VLESS-REALITY-${REALITY_PORT}.json",
      "port": ${REALITY_PORT},
      "listen": "::",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${GENERATE_UUID}",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "dest": "${TLS_SERVER}:443",
          "serverNames": [
            "${TLS_SERVER}",
            ""
          ],
          "publicKey": "${PUBLIC_KEY}",
          "privateKey": "${PRIVATE_KEY}",
          "shortIds": [
            ""
          ]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ]
}
EOF
    [ -z "$PUBLIC_IP" ] && { printf 'Error: Failed to retrieve IP address, configuration generation aborted!\n'; exit 1; }
    {
        echo "-------------------- URL --------------------"
        echo "vless://${GENERATE_UUID}@${PUBLIC_IP}:${REALITY_PORT}?encryption=none&security=reality&flow=xtls-rprx-vision&type=tcp&sni=${TLS_SERVER}&pbk=${PUBLIC_KEY}&fp=chrome#REALITY-${PUBLIC_IP}"
        echo "-------------------- END --------------------"
    } >> "$XRAY_LOGFILE"
fi

if [ "$#" -eq 0 ]; then
    exec xray run -config "$XRAY_WORKDIR/config.json" -confdir "$XRAY_CONFDIR"
else
    exec xray "$@"
fi