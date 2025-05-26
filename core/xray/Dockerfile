# Description: build a lightweight xray image on alpine linux.
#
# Copyright (c) 2025 honeok <honeok@duck.com>
#
# References:
# https://github.com/233boy/Xray
# https://github.com/teddysun/across
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

FROM alpine:latest AS builder

COPY build.sh .

RUN set -ex \
        && apk update \
        && chmod +x build.sh && ./build.sh xray \
        && rm -f build.sh

FROM alpine:latest

COPY --from=builder /tmp/xray/xray /etc/xray/bin/xray
COPY config.json /opt/config.json
COPY build.sh .
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN set -ex \
        && apk update && apk upgrade \
        && apk add --no-cache \
            ca-certificates \
            tzdata \
        && chmod +x docker-entrypoint.sh \
        && chmod +x build.sh && ./build.sh pre \
        && rm -f build.sh \
        && curl -fsL -o /etc/xray/bin/geoip.dat "https://github.com/v2fly/geoip/releases/latest/download/geoip.dat" \
        && curl -fsL -o /etc/xray/bin/geosite.dat "https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat" \
        && rm -rf /var/cache/apk/* /tmp/* \
        && ln -sf /dev/stdout /var/log/xray/access.log \
        && ln -sf /dev/stderr /var/log/xray/error.log

ENV TZ=Asia/Shanghai

CMD [ "/docker-entrypoint.sh" ]