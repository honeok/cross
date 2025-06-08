# Description: This dockerfile is used to build the xray docker image.
#
# Copyright (c) 2025 honeok <honeok@disroot.org>
#
# References:
# https://github.com/233boy/Xray
# https://github.com/teddysun/across
#
# SPDX-License-Identifier: GPL-2.0-only

FROM alpine:latest AS builder
LABEL maintainer="honeok <honeok@disroot.org>"
ARG XRAY_LVER
COPY build.sh .
RUN set -ex \
    && apk update \
    && chmod +x build.sh && ./build.sh build "$XRAY_LVER" \
    && rm -f build.sh \
    && rm -rf /var/cache/apk/*

FROM alpine:latest AS dist
LABEL maintainer="honeok <honeok@disroot.org>"
COPY --from=builder /tmp/xray/xray /etc/xray/bin/xray
COPY config.json /opt/config.json
COPY build.sh .
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN set -ex \
    && apk update && apk upgrade \
    && apk add --no-cache ca-certificates tzdata \
    && chmod +x docker-entrypoint.sh \
    && chmod +x build.sh && ./build.sh before \
    && rm -f build.sh \
    && curl -fsL -o /etc/xray/bin/geoip.dat "https://github.com/v2fly/geoip/releases/latest/download/geoip.dat" \
    && curl -fsL -o /etc/xray/bin/geosite.dat "https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat" \
    && rm -rf /var/cache/apk/* \
    && ln -sf /dev/stdout /var/log/xray/access.log \
    && ln -sf /dev/stderr /var/log/xray/error.log
ENV TZ=Asia/Shanghai
ENTRYPOINT [ "/docker-entrypoint.sh" ]