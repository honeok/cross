#!/usr/bin/env sh
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# References:
# https://sing-box.sagernet.org/zh/configuration
# https://github.com/233boy/sing-box
# https://github.com/fscarmen/sing-box
# https://github.com/RayWangQvQ/sing-box-installer/blob/main/DIY.md
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

set \
    -o errexit \
    -o nounset \
    -o noclobber

SINGBOX_WORKDIR="/etc/sing-box"
SINGBOX_BINDIR="$SINGBOX_WORKDIR/bin"
SINGBOX_CMD="$SINGBOX_BINDIR/sing-box"
SINGBOX_CONFDIR="$SINGBOX_WORKDIR/conf"
SINGBOX_LOGDIR="/var/log/sing-box"
SINGBOX_LOGFILE="$SINGBOX_LOGDIR/access.log"

TLS_SERVERS="aws.amazon.com music.apple.com icloud.cdn-apple.com addons.mozilla.org"
GENERATE_UUID=$(sing-box generate uuid)
GENERATE_KEYS=$(sing-box generate reality-keypair)
PRIVATE_KEY=$(printf "%s" "$GENERATE_KEYS" | sed -n 's/^PrivateKey: *\(.*\)$/\1/p')
PUBLIC_KEY=$(printf "%s" "$GENERATE_KEYS" | sed -n 's/^PublicKey: *\(.*\)$/\1/p')
PUBLIC_IP=$(wget -qO- -L --no-check-certificate --timeout=3 -4 https://one.one.one.one/cdn-cgi/trace | grep ip= | cut -d= -f2 || \
            wget -qO- -L --no-check-certificate --timeout=3 -6 https://one.one.one.one/cdn-cgi/trace | grep ip= | cut -d= -f2)

# Generate default config if not provided by the user
if [ ! -f "$SINGBOX_WORKDIR/config.json" ]; then
    cat > "$SINGBOX_WORKDIR/config.json" <<EOF
{
  "log": {
    "output": "${SINGBOX_LOGFILE}",
    "level": "info",
    "timestamp": true
  },
  "dns": {},
  "ntp": {
    "enabled": true,
    "server": "time.apple.com"
  },
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    }
  ]
}
EOF
fi

if [ -d "$SINGBOX_CONFDIR" ] && [ -z "$(ls -A "$SINGBOX_CONFDIR" 2>/dev/null)" ]; then
    TLS_SERVER=$(echo "$TLS_SERVERS" | tr " " "\n" | shuf -n 1)
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

    {
        echo "-------------------- URL --------------------"
        echo ""
        echo "vless://${GENERATE_UUID}@${PUBLIC_IP}:30000?encryption=none&security=reality&flow=xtls-rprx-vision&type=tcp&sni=${TLS_SERVER}&pbk=${PUBLIC_KEY}&fp=chrome#REALITY-${PUBLIC_IP}"
        echo ""
        echo "-------------------- END --------------------"
    } >> "$SINGBOX_LOGFILE"
fi

if [ "$#" -eq 0 ]; then
    exec "$SINGBOX_CMD" run -c "$SINGBOX_WORKDIR/config.json" -C "$SINGBOX_CONFDIR"
else
    exec "$@"
fi