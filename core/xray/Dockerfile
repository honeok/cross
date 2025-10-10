# Description: This dockerfile is used to build the xray-core docker image for containerized environments.
#
# Copyright (c) 2025 honeok <i@honeok.com>
# SPDX-License-Identifier: GPL-2.0
#
# References:
# https://github.com/233boy/Xray
# https://github.com/teddysun/across

FROM alpine:latest AS base

FROM base AS builder
LABEL maintainer="honeok <i@honeok.com>"
ARG XRAY_VERSION
ARG TARGETOS
ARG TARGETARCH
COPY build.sh .
RUN set -ex \
    && apk add --update --no-cache curl \
    && chmod +x build.sh && ./build.sh build "$XRAY_VERSION" \
    && rm -f build.sh \
    && rm -rf /var/cache/apk/*

FROM base AS dist
LABEL maintainer="honeok <i@honeok.com>"
COPY --from=builder /tmp/xray/xray /etc/xray/bin/xray
COPY config.json /opt/config.json
COPY build.sh .
COPY docker-entrypoint.sh /
RUN set -ex \
    && apk add --update --no-cache bash ca-certificates curl openssl tzdata \
    && chmod +x /docker-entrypoint.sh build.sh \
    && ./build.sh before && rm -f build.sh \
    && curl -Ls https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -o /etc/xray/bin/geoip.dat \
    && curl -Ls https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -o /etc/xray/bin/geosite.dat \
    && rm -rf /var/cache/apk/* \
    && ln -sf /dev/stdout /var/log/xray/access.log \
    && ln -sf /dev/stderr /var/log/xray/error.log
ENV TZ=Asia/Shanghai
ENTRYPOINT ["/docker-entrypoint.sh"]
