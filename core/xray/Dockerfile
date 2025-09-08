# Description: This dockerfile is used to build the xray docker image.
#
# Copyright (c) 2025 honeok <i@honeok.com>
#
# References:
# https://github.com/233boy/Xray
# https://github.com/teddysun/across
#
# SPDX-License-Identifier: GPL-2.0

FROM alpine:latest AS builder
LABEL maintainer="honeok <i@honeok.com>"
ARG XRAY_VERSION
# https://docs.docker.com/build/building/multi-platform
ARG TARGETOS TARGETARCH
COPY build.sh .
RUN set -ex \
    && apk add --update --no-cache curl \
    && chmod +x build.sh && ./build.sh build "$XRAY_VERSION" \
    && rm -f build.sh \
    && rm -rf /var/cache/apk/*

FROM alpine:latest AS dist
LABEL maintainer="honeok <i@honeok.com>"
COPY --from=builder /tmp/xray/xray /etc/xray/bin/xray
COPY config.json /opt/config.json
COPY build.sh .
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN set -ex \
    && apk add --update --no-cache ca-certificates curl tzdata \
    && chmod +x /docker-entrypoint.sh build.sh \
    && ./build.sh before && rm -f build.sh \
    && curl -Lso /etc/xray/bin/geoip.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat \
    && curl -Lso /etc/xray/bin/geosite.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat \
    && rm -rf /var/cache/apk/* \
    && ln -sf /dev/stdout /var/log/xray/access.log \
    && ln -sf /dev/stderr /var/log/xray/error.log
ENV TZ=Asia/Shanghai
ENTRYPOINT [ "/docker-entrypoint.sh" ]