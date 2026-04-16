# syntax=docker/dockerfile:1
# SPDX-License-Identifier: GPL-2.0
# Copyright (c) 2025-2026 honeok <i@honeok.com>

FROM --platform=$TARGETPLATFORM alpine:3.23.4@sha256:5b10f432ef3da1b8d4c7eb6c487f2f5a8f096bc91145e68878dd4a5019afde11
LABEL maintainer="honeok <i@honeok.com>"
ARG TARGETARCH
ARG TARGETVARIANT
COPY config.json /opt/config.json
COPY --chmod=755 docker-entrypoint.sh /
COPY --chmod=755 xray-${TARGETARCH}${TARGETVARIANT} /etc/xray/bin/xray
COPY *.dat /etc/xray/bin/
RUN set -ex \
    && apk add --no-cache --update curl ca-certificates tzdata \
    && mkdir -p /etc/xray/conf /var/log/xray \
    && touch /var/log/xray/access.log /var/log/xray/error.log \
    && ln -sf /etc/xray/bin/xray /usr/local/bin/xray \
    && ln -sf /dev/stdout /var/log/xray/access.log \
    && ln -sf /dev/stderr /var/log/xray/error.log
ENV TZ=Asia/Shanghai
ENTRYPOINT ["/docker-entrypoint.sh"]
