#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
#
# Description: The script is used to automatically update cloudflare dns records with optimized ip addresses.
# Copyright (c) 2026 honeok <i@honeok.com>
#
# Thanks:
# https://ip.v2too.top

set -eEuo pipefail

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH

# cloudflare 基础变量
: "${CLOUDFLARE_API_TOKEN:?missing CLOUDFLARE_API_TOKEN}"
: "${CLOUDFLARE_ZONE_ID:?missing CLOUDFLARE_ZONE_ID}"
: "${CLOUDFLARE_RECORD_NAME:?missing CLOUDFLARE_RECORD_NAME}"

IPV4_RE='^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$'

_log() {
    printf '[%s] %s\n' "$(date -u '+%F %T')" "$*"
}

curl() {
    local rc

    # 添加 --fail 不然404退出码也为0
    # 32位cygwin已停止更新, 证书可能有问题, 添加 --insecure
    # centos7 curl 不支持 --retry-connrefused --retry-all-errors 因此手动 retry
    for ((i = 1; i <= 5; i++)); do
        command curl --connect-timeout 10 --fail --insecure "$@"
        rc="$?"
        if [ "$rc" -eq 0 ]; then
            return
        else
            # 403 404 错误或达到重试次数
            if [ "$rc" -eq 22 ] || [ "$i" -eq 5 ]; then
                return "$rc"
            fi
            sleep 0.5
        fi
    done
}

# 获取数据源
CLOUDFLARE_BESTIP_API="$(
    curl -Ls https://ip.v2too.top/api/nodes |
        jq -r '
            map(select(.carrier == "ct"))
            | sort_by(-(.speed | tonumber? // 0))
            | .[:5][]
            | .ip
        ' |
        grep -E "$IPV4_RE" |
        awk '!seen[$0]++' || true
)"

main() {
    local ip cloudflare_create_body

    # API 为空时直接退出
    if [ -z "$CLOUDFLARE_BESTIP_API" ]; then
        _log "CLOUDFLARE_BESTIP_API is empty, skip."
        exit 0
    fi

    # 删除当前域名所有同名 A 记录
    curl -Ls -G "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" \
        --data-urlencode "type=A" \
        --data-urlencode "name=$CLOUDFLARE_RECORD_NAME" \
        --data-urlencode "per_page=1000" |
        jq -r '.result[]?.id' |
        while IFS= read -r record_id; do
            [ -n "$record_id" ] || continue
            curl -Ls -X DELETE "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/$record_id" \
                -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
                -H "Content-Type: application/json" | jq .
        done

    # 按 API 结果重新创建
    while IFS= read -r ip; do
        [ -n "$ip" ] || continue

        cloudflare_create_body="$(
            jq -n \
                --arg type A \
                --arg name "$CLOUDFLARE_RECORD_NAME" \
                --arg content "$ip" \
                --argjson ttl 60 \
                --argjson proxied false \
                '{
                    type: $type,
                    name: $name,
                    content: $content,
                    ttl: $ttl,
                    proxied: $proxied
                }'
        )"

        curl -Ls -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records" \
            -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
            -H "Content-Type: application/json" \
            --data "$cloudflare_create_body" | jq .
    done <<< "$CLOUDFLARE_BESTIP_API"
}

main "$@"
