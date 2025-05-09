# Description: Dockerfile to build a lightweight 3x-ui image on Alpine Linux.
#
# Copyright (c) 2025 honeok <honeok@duck.com>
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

FROM golang:1-alpine AS builder

WORKDIR /go/src

COPY build.sh .

RUN set -ex \
        && apk update && apk upgrade \
        && apk add --no-cache \
            build-base \
            gcc \
            git \
        && chmod +x build.sh && ./build.sh \
        && TAG=$(curl -fsL https://api.github.com/repos/MHSanaei/3x-ui/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') \
        && git clone --depth=1 --branch "$TAG" https://github.com/MHSanaei/3x-ui.git \
        && cd 3x-ui \
        && CGO_ENABLED=1 GOOS=$TARGETOS CGO_CFLAGS="-D_LARGEFILE64_SOURCE" GO111MODULE=on \
        && go build -a -trimpath -ldflags "-s -w -linkmode external -extldflags '-static'" -o /go/bin/3x-ui \
        && cd .. \
        && rm -rf /go/src/3x-ui /var/cache/apk/*

FROM alpine:latest

# https://docs.docker.com/build/building/multi-platform/
ARG TARGETARCH

WORKDIR /usr/local/bin

COPY --from=builder /go/bin/3x-ui /usr/local/bin/3x-ui
COPY --from=builder /tmp/xray/xray /usr/local/bin/bin/xray-linux-${TARGETARCH}
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY x-ui.sh /usr/local/bin/x-ui

RUN set -ex \
        && apk update && apk upgrade \
        && apk add --no-cache \
            bash \
            ca-certificates \
            curl \
            tzdata \
        && chmod +x /docker-entrypoint.sh /usr/local/bin/x-ui \
        && curl -fsL -o /usr/local/bin/bin/geoip.dat "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat" \
        && curl -fsL -o /usr/local/bin/bin/geosite.dat "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat" \
        && curl -fsL -o /usr/local/bin/bin/geoip_IR.dat "https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geoip.dat" \
        && curl -fsL -o /usr/local/bin/bin/geosite_IR.dat "https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geosite.dat" \
        && curl -fsL -o /usr/local/bin/bin/geoip_RU.dat "https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geoip.dat" \
        && curl -fsL -o /usr/local/bin/bin/geosite_RU.dat "https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geosite.dat" \
        && rm -rf /var/cache/apk/* /tmp/*

VOLUME [ "/etc/x-ui" ]

ENV TZ=Asia/Shanghai

ENTRYPOINT [ "/docker-entrypoint.sh" ]