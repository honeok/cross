# syntax=docker/dockerfile:1

FROM alpine:3.24.1@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b AS dist
LABEL org.opencontainers.image.authors="honeok <i@honeok.com>"
ARG SINGBOX_VERSION TARGETOS TARGETARCH TARGETVARIANT
RUN set -ex \
    && apk add --no-cache --update bash ca-certificates nftables tzdata \
    && wget -qO- "https://github.com/SagerNet/sing-box/releases/download/$SINGBOX_VERSION/sing-box-${SINGBOX_VERSION#v}-$TARGETOS-$TARGETARCH$TARGETVARIANT.tar.gz" | \
        tar xz --strip-components=1 -C /usr/local/bin "sing-box-${SINGBOX_VERSION#v}-$TARGETOS-$TARGETARCH$TARGETVARIANT/sing-box" \
    && chmod +x /usr/local/bin/sing-box
ENTRYPOINT ["sing-box"]
