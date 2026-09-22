# syntax=docker/dockerfile:1

FROM alpine:3.24.2@sha256:294b683cb724975bec92580e1e685676bd4b50bda910ddb8c51d4cabeaec77e6 AS dist
LABEL maintainer="honeok <i@honeok.com>"
ARG MIHOMO_VERSION TARGETOS TARGETARCH TARGETVARIANT
RUN set -ex \
    && apk add --no-cache --update bash ca-certificates nftables tzdata \
    && wget -qO- "https://github.com/MetaCubeX/mihomo/releases/download/$MIHOMO_VERSION/mihomo-$TARGETOS-$TARGETARCH$TARGETVARIANT-$MIHOMO_VERSION.gz" | gzip -d > /usr/local/bin/mihomo \
    && chmod +x /usr/local/bin/mihomo
COPY *.dat /root/.config/mihomo
COPY geoip.metadb /root/.config/mihomo
COPY GeoLite2-ASN.mmdb /root/.config/mihomo
ENV TZ=Asia/Shanghai
VOLUME ["/root/.config/mihomo"]
ENTRYPOINT ["mihomo"]
