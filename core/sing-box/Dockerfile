# Description: This dockerfile is used to build the sing-box docker image.
#
# Copyright (c) 2025 honeok <honeok@disroot.org>
#
# References:
# https://github.com/SagerNet/sing-box
# https://github.com/fscarmen/Sing-box-image
# https://github.com/RayWangQvQ/sing-box-installer
#
# SPDX-License-Identifier: GPL-2.0-only

FROM alpine:latest AS dist
LABEL maintainer="honeok <honeok@disroot.org>"
ARG SINGBOX_LVER
# https://docs.docker.com/build/building/multi-platform
ARG TARGETOS TARGETARCH
COPY build.sh .
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN set -ex \
    && apk update && apk upgrade \
    && apk add --no-cache ca-certificates curl tzdata \
    && chmod +x /docker-entrypoint.sh build.sh \
    && ./build.sh "$SINGBOX_LVER" && rm -f build.sh \
    && rm -rf /var/cache/apk/* \
    && ln -sf /dev/stdout /var/log/sing-box/access.log
ENV TZ=Asia/Shanghai
ENTRYPOINT [ "/docker-entrypoint.sh" ]