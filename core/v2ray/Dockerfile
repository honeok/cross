# Description: This dockerfile is used to build the v2ray container image.
#
# Copyright (c) 2025 honeok <honeok@duck.com>
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

FROM golang:1-alpine AS builder
LABEL maintainer="honeok <honeok@duck.com"
WORKDIR /go/src
ARG TARGETOS TARGETARCH
ARG GOPROXY=""
ARG VERSION
ENV CGO_ENABLED=0
ENV GOOS=$TARGETOS
ENV GOARCH=$TARGETARCH
COPY build.sh .
RUN set -ex \
    && apk add --no-cache build-base git \
    && chmod +x build.sh && ./build.sh ${VERSION} \
    && rm -rf /var/cache/apk/*

FROM alpine:latest
LABEL maintainer="honeok <honeok@duck.com"
COPY --from=builder /go/bin/v2ray /usr/bin/v2ray
COPY config.json /etc/v2ray/config.json
RUN set -ex \
    && apk upgrade \
    && apk add --no-cache ca-certificates tzdata \
    && mkdir -p /usr/share/v2ray /var/log/v2ray \
    && wget -qO /usr/share/v2ray/geosite.dat "https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat" \
    && wget -qO /usr/share/v2ray/geoip-only-cn-private.dat "https://github.com/v2fly/geoip/releases/latest/download/geoip-only-cn-private.dat" \
    && wget -qO /usr/share/v2ray/geoip.dat "https://github.com/v2fly/geoip/releases/latest/download/geoip.dat" \
    && ln -sf /dev/stdout /var/log/v2ray/access.log \
    && ln -sf /dev/stderr /var/log/v2ray/error.log \
    && rm -rf /var/cache/apk/*
VOLUME /etc/v2ray
ENV TZ=Asia/Shanghai
ENTRYPOINT [ "/usr/bin/v2ray" ]
CMD [ "run", "-config", "/etc/v2ray/config.json" ]