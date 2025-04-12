# Description: Dockerfile to build a lightweight x-ui image on Alpine Linux.
#
# Copyright (c) 2025 honeok <honeok@duck.com>
#
# References:
# https://github.com/enwaiax/x-ui
# https://github.com/FranzKafkaYu/x-ui
# https://github.com/XTLS/Xray-core
# https://github.com/v2fly/domain-list-community
# https://github.com/v2fly/geoip
#
# Acknowledgments:
# https://github.com/teddysun
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

FROM --platform=$BUILDPLATFORM alpine:latest AS builder

COPY build.sh .

RUN set -ex \
        && chmod +x build.sh && ./build.sh

FROM --platform=$BUILDPLATFORM alpine:latest

# https://docs.docker.com/build/building/multi-platform/
ARG TARGETARCH

# The contextual runtime relationship of x-ui
WORKDIR /usr/local/bin

# Due to the need to use a management script, rename the x-ui process.
COPY --from=builder /tmp/x-ui/x-ui /usr/local/bin/xray-ui
COPY --from=builder /tmp/xray/xray /usr/local/bin/bin/xray-linux-${TARGETARCH}
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY x-ui.sh /usr/local/bin/x-ui

RUN set -ex \
        && apk update && apk upgrade \
        && apk add --no-cache \
            bash \
            ca-certificates \
            curl \
            iptables \
            tzdata \
        && chmod +x /docker-entrypoint.sh /usr/local/bin/x-ui \
        && curl -fsSL -o /usr/local/bin/bin/geosite.dat "https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat" \
        && curl -fsSL -o /usr/local/bin/bin/geoip.dat "https://github.com/v2fly/geoip/releases/latest/download/geoip.dat" \
        && rm -rf /var/cache/apk/* /tmp/*

VOLUME [ "/etc/x-ui" ]

# default time of the container
ENV TZ=Asia/Shanghai

ENTRYPOINT [ "/docker-entrypoint.sh" ]