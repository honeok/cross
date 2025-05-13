#!/usr/bin/env sh
#
# Copyright (c) 2025 honeok <honeok@duck.com>
#
# References:
# https://sing-box.sagernet.org/zh/configuration
# https://github.com/233boy/sing-box
# https://github.com/fscarmen/sing-box
# https://github.com/RayWangQvQ/sing-box-installer
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

set \
    -o errexit \
    -o nounset

SINGBOX_WORKDIR="/etc/sing-box"
SINGBOX_BINDIR="$SINGBOX_WORKDIR/bin"
SINGBOX_CONFDIR="$SINGBOX_WORKDIR/conf"
SINGBOX_LOGDIR="/var/log/sing-box"
SINGBOX_LOGFILE="$SINGBOX_LOGDIR/access.log"
CLOUDFLARE_API="www.qualcomm.cn"
PUBLIC_IP=$(curl -fsL -m 5 -4 "http://$CLOUDFLARE_API/cdn-cgi/trace" 2>/dev/null | awk -F'=' '/^ip=/ {print $2}' || \
            curl -fsL -m 5 -6 "http://$CLOUDFLARE_API/cdn-cgi/trace" 2>/dev/null | awk -F'=' '/^ip=/ {print $2}')

if [ ! -s "$SINGBOX_BINDIR/tls.key" ] || [ ! -s "$SINGBOX_BINDIR/tls.cer" ]; then
    # tls generation
    GENERATE_TLS_KEY=$(sing-box generate tls-keypair tls -m 456)
    TLS_PRIVATE_KEY=$(printf "%s\n" "$GENERATE_TLS_KEY" | awk '/-----BEGIN PRIVATE KEY-----/{p=1} p{print} /-----END PRIVATE KEY-----/{p=0;exit}')
    TLS_CERTIFICATE=$(printf "%s\n" "$GENERATE_TLS_KEY" | awk '/-----BEGIN CERTIFICATE-----/{p=1} p{print} /-----END CERTIFICATE-----/{p=0;exit}')
    echo "$TLS_PRIVATE_KEY" > "$SINGBOX_BINDIR/tls.key"
    echo "$TLS_CERTIFICATE" > "$SINGBOX_BINDIR/tls.cer"
fi

# Generate default config if not provided by the user
if [ ! -s "$SINGBOX_WORKDIR/config.json" ]; then
    cat > "$SINGBOX_WORKDIR/config.json" <<EOF
{
  "log": {
    "output": "${SINGBOX_LOGFILE}",
    "level": "info",
    "timestamp": true
  },
  "dns": {},
  "outbounds": [
    {
      "tag": "direct",
      "type": "direct"
    }
  ]
}
EOF
fi

if [ -d "$SINGBOX_CONFDIR" ] && [ -z "$(ls -A "$SINGBOX_CONFDIR" 2>/dev/null)" ]; then
    # https://github.com/XTLS/Xray-core/issues/2005
    TLS_SERVERS="www.icloud.com apps.apple.com music.apple.com icloud.cdn-apple.com updates.cdn-apple.com"
    GENERATE_UUID=$(sing-box generate uuid || cat /proc/sys/kernel/random/uuid)
    GENERATE_KEYS=$(sing-box generate reality-keypair)
    PRIVATE_KEY=$(printf "%s" "$GENERATE_KEYS" | sed -n 's/^PrivateKey: *\(.*\)$/\1/p')
    PUBLIC_KEY=$(printf "%s" "$GENERATE_KEYS" | sed -n 's/^PublicKey: *\(.*\)$/\1/p')
    TLS_SERVER=$(printf "%s" "$TLS_SERVERS" | tr " " "\n" | shuf -n 1)
    cat > "$SINGBOX_CONFDIR/VLESS-REALITY-30000.json" <<EOF
{
  "inbounds": [
    {
      "tag": "VLESS-REALITY-30000.json",
      "type": "vless",
      "listen": "::",
      "listen_port": 30000,
      "users": [
        {
          "flow": "xtls-rprx-vision",
          "uuid": "${GENERATE_UUID}"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": "${TLS_SERVER}",
        "reality": {
          "enabled": true,
          "handshake": {
            "server": "${TLS_SERVER}",
            "server_port": 443
          },
          "private_key": "${PRIVATE_KEY}",
          "short_id": [
            ""
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct"
    },
    {
      "tag": "public_key_${PUBLIC_KEY}",
      "type": "direct"
    }
  ]
}
EOF

    [ -z "$PUBLIC_IP" ] && { printf 'Error: Failed to retrieve IP address, configuration generation aborted!\n'; exit 1; }

    {
        echo "-------------------- URL --------------------"
        echo "vless://${GENERATE_UUID}@${PUBLIC_IP}:30000?encryption=none&security=reality&flow=xtls-rprx-vision&type=tcp&sni=${TLS_SERVER}&pbk=${PUBLIC_KEY}&fp=chrome#REALITY-${PUBLIC_IP}"
        echo "-------------------- END --------------------"
    } >> "$SINGBOX_LOGFILE"
fi

if [ "$#" -eq 0 ]; then
    exec "sing-box" run -c "$SINGBOX_WORKDIR/config.json" -C "$SINGBOX_CONFDIR"
else
    exec "$@"
fi