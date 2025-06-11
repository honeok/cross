# Description: This dockerfile is used to build the 3x-ui image in container.
#
# Copyright (c) 2025 honeok <honeok@disroot.org>
#
# References:
# https://docs.docker.com/build/building/multi-platform
#
# SPDX-License-Identifier: GPL-2.0-only

FROM golang:1-alpine AS builder
LABEL maintainer="honeok <honeok@disroot.org>"
WORKDIR /go/src/github.com/MHSanaei/3x-ui
ARG XRAY_LVER
ARG XUI_LTAG
ARG TARGETOS TARGETARCH
ENV CGO_ENABLED=1
COPY build.sh .
RUN set -ex \
    && apk update \
    && apk add --no-cache build-base gcc git \
    && chmod +x build.sh && ./build.sh "$XRAY_LVER" \
    && git clone --depth=1 --branch "$XUI_LTAG" https://github.com/MHSanaei/3x-ui.git ./3x-ui \
    && cd 3x-ui \
    && CGO_CFLAGS="-D_LARGEFILE64_SOURCE" GO111MODULE=on \
    && go build -a -trimpath -ldflags "-s -w -linkmode external -extldflags '-static'" -o /go/bin/3x-ui \
    && rm -rf /var/cache/apk/*

FROM alpine:latest AS dist
LABEL maintainer="honeok <honeok@disroot.org>"
WORKDIR /usr/local/bin
ARG TARGETARCH
COPY --from=builder /go/bin/3x-ui /usr/local/bin/3x-ui
COPY --from=builder /tmp/xray/xray /usr/local/bin/bin/xray-linux-${TARGETARCH}
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY x-ui.sh /usr/local/bin/x-ui
RUN set -ex \
    && apk update && apk upgrade \
    && apk add --no-cache bash ca-certificates curl tzdata \
    && chmod +x /docker-entrypoint.sh /usr/local/bin/x-ui \
    && curl -fsL -o /usr/local/bin/bin/geoip.dat "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat" \
    && curl -fsL -o /usr/local/bin/bin/geosite.dat "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat" \
    && curl -fsL -o /usr/local/bin/bin/geoip_IR.dat "https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geoip.dat" \
    && curl -fsL -o /usr/local/bin/bin/geosite_IR.dat "https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geosite.dat" \
    && curl -fsL -o /usr/local/bin/bin/geoip_RU.dat "https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geoip.dat" \
    && curl -fsL -o /usr/local/bin/bin/geosite_RU.dat "https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geosite.dat" \
    && rm -rf /var/cache/apk/*
VOLUME [ "/etc/x-ui" ]
ENV TZ=Asia/Shanghai
ENTRYPOINT [ "/docker-entrypoint.sh" ]