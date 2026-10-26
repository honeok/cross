# syntax=docker/dockerfile:1
# SPDX-License-Identifier: GPL-2.0
# Copyright (c) 2025-2026 honeok <i@honeok.com>

FROM --platform=$TARGETPLATFORM alpine:3.24.3@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a
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
