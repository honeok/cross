# syntax=docker/dockerfile:1

FROM alpine:3.23.4@sha256:5b10f432ef3da1b8d4c7eb6c487f2f5a8f096bc91145e68878dd4a5019afde11 AS dist
LABEL org.opencontainers.image.authors="honeok <i@honeok.com>"
ARG SINGBOX_VERSION TARGETOS TARGETARCH TARGETVARIANT
RUN set -ex \
    && apk add --no-cache --update bash ca-certificates nftables tzdata \
    && wget -qO- "https://github.com/SagerNet/sing-box/releases/download/$SINGBOX_VERSION/sing-box-${SINGBOX_VERSION#v}-$TARGETOS-$TARGETARCH$TARGETVARIANT.tar.gz" | \
        tar xz --strip-components=1 -C /usr/local/bin "sing-box-${SINGBOX_VERSION#v}-$TARGETOS-$TARGETARCH$TARGETVARIANT/sing-box" \
    && chmod +x /usr/local/bin/sing-box
ENTRYPOINT ["sing-box"]
