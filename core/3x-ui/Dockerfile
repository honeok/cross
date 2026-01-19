# syntax=docker/dockerfile:1
# SPDX-License-Identifier: GPL-2.0
# Copyright (c) 2025-2026 honeok <i@honeok.com>
#
# References:
# https://docs.docker.com/build/building/multi-platform

FROM golang:1.25-alpine@sha256:d9b2e14101f27ec8d09674cd01186798d227bb0daec90e032aeb1cd22ac0f029 AS builder
LABEL maintainer="honeok <i@honeok.com>"
WORKDIR /go/src/github.com/MHSanaei/3x-ui
ARG XRAY_VERSION
ARG XUI_TAG
ARG TARGETOS TARGETARCH
ENV CGO_ENABLED=1
ENV CGO_CFLAGS="-D_LARGEFILE64_SOURCE"
COPY --chmod=755 build.sh .
RUN set -ex \
    && apk add --update --no-cache build-base curl gcc git \
    && ./build.sh "$XRAY_VERSION" \
    && rm -f build.sh \
    && git clone --depth=1 --branch "$XUI_TAG" https://github.com/MHSanaei/3x-ui.git . \
    && go mod download \
    && go build -v -trimpath -o /go/bin/3x-ui -ldflags "-s -w -buildid= -linkmode external -extldflags '-static'"

FROM alpine:3.23.2@sha256:865b95f46d98cf867a156fe4a135ad3fe50d2056aa3f25ed31662dff6da4eb62 AS dist
LABEL maintainer="honeok <i@honeok.com>"
WORKDIR /usr/local/bin
ARG TARGETARCH
COPY --from=builder /go/bin/3x-ui /usr/local/bin/3x-ui
COPY --from=builder /tmp/xray/xray /usr/local/bin/bin/xray-linux-${TARGETARCH}
COPY --chmod=755 docker-entrypoint.sh /
COPY *.dat /usr/local/bin/bin/
RUN set -ex \
    && apk add --update --no-cache bash ca-certificates curl tzdata
VOLUME ["/etc/x-ui"]
ENV TZ=Asia/Shanghai
ENTRYPOINT ["/docker-entrypoint.sh"]
