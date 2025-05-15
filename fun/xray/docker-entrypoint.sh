#!/usr/bin/env sh
#
# Description: This script is used to configure xray during container initialization.
#
# Copyright (c) 2025 honeok <honeok@duck.com>
#
# References:
# https://github.com/233boy/Xray
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

set \
    -o errexit \
    -o nounset

XRAY_WORKDIR="/etc/xray"
XRAY_CONFDIR="$XRAY_WORKDIR/conf"
XRAY_LOGDIR="/var/log/xray"
XRAY_LOGFILE="$XRAY_LOGDIR/access.log"
CLOUDFLARE_API="www.qualcomm.cn"
PUBLIC_IP=$(curl -fsL -m 5 -4 "http://$CLOUDFLARE_API/cdn-cgi/trace" 2>/dev/null | grep -i '^ip=' | cut -d'=' -f2 | grep . || \
            curl -fsL -m 5 -6 "http://$CLOUDFLARE_API/cdn-cgi/trace" 2>/dev/null | grep -i '^ip=' | cut -d'=' -f2 | grep .)

[ ! -s "$XRAY_WORKDIR/config.json" ] && cat /opt/config.json > "$XRAY_WORKDIR/config.json"

if [ -d "$XRAY_CONFDIR" ] && [ -z "$(ls -A "$XRAY_CONFDIR" 2>/dev/null)" ]; then
    # https://github.com/XTLS/Xray-core/issues/2005
    TLS_SERVERS="www.icloud.com apps.apple.com music.apple.com icloud.cdn-apple.com updates.cdn-apple.com"
    GENERATE_UUID=$(xray uuid || cat /proc/sys/kernel/random/uuid)
    GENERATE_KEYS=$(xray x25519)
    PRIVATE_KEY=$(printf "%s" "$GENERATE_KEYS" | sed -n 's/^Private key: *\(.*\)$/\1/p')
    PUBLIC_KEY=$(printf "%s" "$GENERATE_KEYS" | sed -n 's/^Public key: *\(.*\)$/\1/p')
    TLS_SERVER=$(printf "%s" "$TLS_SERVERS" | tr " " "\n" | shuf -n 1)
    cat > "$XRAY_CONFDIR/VLESS-REALITY-30000.json" <<EOF
{
  "inbounds": [
    {
      "tag": "VLESS-REALITY-30000.json",
      "port": 30000,
      "listen": "0.0.0.0",
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
        echo "vless://${GENERATE_UUID}@${PUBLIC_IP}:30000?encryption=none&security=reality&flow=xtls-rprx-vision&type=tcp&sni=${TLS_SERVER}&pbk=${PUBLIC_KEY}&fp=chrome#REALITY-${PUBLIC_IP}"
        echo "-------------------- END --------------------"
    } >> "$XRAY_LOGFILE"
fi

if [ "$#" -eq 0 ]; then
    exec "xray" run -config "$XRAY_WORKDIR/config.json" -confdir "$XRAY_CONFDIR"
else
    exec "$@"
fi