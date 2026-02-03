# syntax=docker/dockerfile:1

FROM alpine:3.23.3@sha256:25109184c71bdad752c8312a8623239686a9a2071e8825f20acb8f2198c3f659 AS dist
LABEL org.opencontainers.image.authors="honeok <i@honeok.com>"
ARG SINGBOX_VERSION TARGETOS TARGETARCH TARGETVARIANT
RUN set -ex \
    && apk add --no-cache --update bash ca-certificates nftables tzdata \
    && wget -qO- "https://github.com/SagerNet/sing-box/releases/download/$SINGBOX_VERSION/sing-box-${SINGBOX_VERSION#v}-$TARGETOS-$TARGETARCH$TARGETVARIANT.tar.gz" | \
        tar xz --strip-components=1 -C /usr/local/bin "sing-box-${SINGBOX_VERSION#v}-$TARGETOS-$TARGETARCH$TARGETVARIANT/sing-box" \
    && chmod +x /usr/local/bin/sing-box
ENTRYPOINT ["sing-box"]
