# syntax=docker/dockerfile:1
# SPDX-License-Identifier: GPL-2.0
# Copyright (c) 2025-2026 honeok <i@honeok.com>

FROM --platform=$TARGETPLATFORM alpine:3.24.4@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf
LABEL org.opencontainers.image.authors="honeok <i@honeok.com>"
ARG TARGETARCH TARGETVARIANT
RUN set -ex \
    && apk add --no-cache --update curl ca-certificates tzdata \
    && mkdir -p /etc/xray/ /var/log/xray
COPY --chmod=755 xray-$TARGETARCH$TARGETVARIANT /usr/bin/xray
COPY --chmod=644 *.dat /usr/share/xray/
ADD https://fastly.jsdelivr.net/gh/teddysun/across@master/docker/xray/config.json /etc/xray/config.json
ENV TZ=Asia/Shanghai
VOLUME /etc/xray
CMD ["/usr/bin/xray", "-config", "/etc/xray/config.json"]
