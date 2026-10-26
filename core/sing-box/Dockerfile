# syntax=docker/dockerfile:1

FROM alpine:3.24.3@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a AS dist
LABEL org.opencontainers.image.authors="honeok <i@honeok.com>"
ARG SINGBOX_VERSION TARGETOS TARGETARCH TARGETVARIANT
RUN set -ex \
    && apk add --no-cache --update bash ca-certificates nftables tzdata \
    && wget -qO- "https://github.com/SagerNet/sing-box/releases/download/$SINGBOX_VERSION/sing-box-${SINGBOX_VERSION#v}-$TARGETOS-$TARGETARCH$TARGETVARIANT.tar.gz" | \
        tar xz --strip-components=1 -C /usr/local/bin "sing-box-${SINGBOX_VERSION#v}-$TARGETOS-$TARGETARCH$TARGETVARIANT/sing-box" \
    && chmod +x /usr/local/bin/sing-box
ENTRYPOINT ["sing-box"]
