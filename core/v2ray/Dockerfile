# Description: This dockerfile is used to build the v2ray container image.
#
# Copyright (c) 2025 honeok <honeok@disroot.org>
#
# SPDX-License-Identifier: GPL-2.0-only

FROM golang:1-alpine AS builder
LABEL maintainer="honeok <honeok@disroot.org>"
WORKDIR /go/src/github.com/v2fly/v2ray-core
ARG V2RAY_LTAG
ENV CGO_ENABLED=0
COPY build.sh .
RUN set -ex \
    && apk add --no-cache build-base git \
    && chmod +x build.sh && ./build.sh "$V2RAY_LTAG" \
    && rm -rf /var/cache/apk/*

FROM alpine:latest AS dist
LABEL maintainer="honeok <honeok@disroot.org>"
COPY --from=builder /go/bin/v2ray /usr/bin/v2ray
COPY config.json /etc/v2ray/config.json
RUN set -ex \
    && apk upgrade \
    && apk add --no-cache ca-certificates tzdata \
    && mkdir -p /usr/share/v2ray /var/log/v2ray \
    && wget -qO /usr/share/v2ray/geosite.dat "https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat" \
    && wget -qO /usr/share/v2ray/geoip-only-cn-private.dat "https://github.com/v2fly/geoip/releases/latest/download/geoip-only-cn-private.dat" \
    && wget -qO /usr/share/v2ray/geoip.dat "https://github.com/v2fly/geoip/releases/latest/download/geoip.dat" \
    && ln -sf /dev/stdout /var/log/v2ray/access.log \
    && ln -sf /dev/stderr /var/log/v2ray/error.log \
    && rm -rf /var/cache/apk/*
VOLUME /etc/v2ray
ENV TZ=Asia/Shanghai
ENTRYPOINT [ "/usr/bin/v2ray" ]
CMD [ "run", "-config", "/etc/v2ray/config.json" ]