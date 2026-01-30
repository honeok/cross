# syntax=docker/dockerfile:1
# SPDX-License-Identifier: GPL-2.0
# Copyright (c) 2025-2026 honeok <i@honeok.com>

FROM --platform=$TARGETPLATFORM alpine:3.23.3@sha256:25109184c71bdad752c8312a8623239686a9a2071e8825f20acb8f2198c3f659
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
