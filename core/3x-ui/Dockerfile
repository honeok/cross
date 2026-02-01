# syntax=docker/dockerfile:1
# SPDX-License-Identifier: GPL-2.0
# Copyright (c) 2025-2026 honeok <i@honeok.com>
#
# References:
# https://docs.docker.com/build/building/multi-platform

FROM golang:1.25-alpine@sha256:98e6cffc31ccc44c7c15d83df1d69891efee8115a5bb7ede2bf30a38af3e3c92 AS builder
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

FROM alpine:3.23.3@sha256:25109184c71bdad752c8312a8623239686a9a2071e8825f20acb8f2198c3f659 AS dist
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
