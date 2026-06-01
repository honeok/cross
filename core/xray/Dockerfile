# syntax=docker/dockerfile:1
# SPDX-License-Identifier: GPL-2.0
# Copyright (c) 2025-2026 honeok <i@honeok.com>

FROM --platform=$TARGETPLATFORM alpine:3.23.4@sha256:5b10f432ef3da1b8d4c7eb6c487f2f5a8f096bc91145e68878dd4a5019afde11
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
