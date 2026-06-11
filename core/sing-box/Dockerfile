# syntax=docker/dockerfile:1

FROM alpine:3.24.0@sha256:a2d49ea686c2adfe3c992e47dc3b5e7fa6e6b5055609400dc2acaeb241c829f4 AS dist
LABEL org.opencontainers.image.authors="honeok <i@honeok.com>"
ARG SINGBOX_VERSION TARGETOS TARGETARCH TARGETVARIANT
RUN set -ex \
    && apk add --no-cache --update bash ca-certificates nftables tzdata \
    && wget -qO- "https://github.com/SagerNet/sing-box/releases/download/$SINGBOX_VERSION/sing-box-${SINGBOX_VERSION#v}-$TARGETOS-$TARGETARCH$TARGETVARIANT.tar.gz" | \
        tar xz --strip-components=1 -C /usr/local/bin "sing-box-${SINGBOX_VERSION#v}-$TARGETOS-$TARGETARCH$TARGETVARIANT/sing-box" \
    && chmod +x /usr/local/bin/sing-box
ENTRYPOINT ["sing-box"]
