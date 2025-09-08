# Description: This dockerfile is used to build the 3x-ui image in container.
#
# Copyright (c) 2025 honeok <i@honeok.com>
#
# References:
# https://docs.docker.com/build/building/multi-platform
#
# SPDX-License-Identifier: GPL-2.0

FROM golang:1.25-alpine AS builder
LABEL maintainer="honeok <i@honeok.com>"
WORKDIR /go/src/github.com/MHSanaei/3x-ui
ARG XRAY_VERSION
ARG XUI_TAG
ARG TARGETOS TARGETARCH
ENV CGO_ENABLED=1
ENV CGO_CFLAGS="-D_LARGEFILE64_SOURCE"
ENV GO111MODULE=on
COPY build.sh .
RUN set -ex \
    && apk add --update --no-cache build-base curl gcc git \
    && chmod +x build.sh && ./build.sh "$XRAY_VERSION" \
    && rm -f build.sh \
    && git clone --depth=1 --branch "$XUI_TAG" https://github.com/MHSanaei/3x-ui.git . \
    && go mod tidy -v \
    && go build -a -trimpath -ldflags "\
        -s -w -linkmode external -extldflags '-static'" \
        -o /go/bin/3x-ui ./main.go \
    && rm -rf /var/cache/apk/*

FROM alpine:latest AS dist
LABEL maintainer="honeok <i@honeok.com>"
WORKDIR /usr/local/bin
ARG TARGETARCH
COPY --from=builder /go/bin/3x-ui /usr/local/bin/3x-ui
COPY --from=builder /tmp/xray/xray /usr/local/bin/bin/xray-linux-${TARGETARCH}
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN set -ex \
    && apk add --update --no-cache bash ca-certificates curl tzdata \
    && chmod +x /docker-entrypoint.sh \
    && curl -Lso /usr/local/bin/bin/geoip.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat \
    && curl -Lso /usr/local/bin/bin/geosite.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat \
    && curl -Lso /usr/local/bin/bin/geoip_IR.dat https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geoip.dat \
    && curl -Lso /usr/local/bin/bin/geosite_IR.dat https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geosite.dat \
    && curl -Lso /usr/local/bin/bin/geoip_RU.dat https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geoip.dat \
    && curl -Lso /usr/local/bin/bin/geosite_RU.dat https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geosite.dat \
    && rm -rf /var/cache/apk/*
VOLUME [ "/etc/x-ui" ]
ENV TZ=Asia/Shanghai
ENTRYPOINT [ "/docker-entrypoint.sh" ]