# Description: Dockerfile to build a lightweight Sing-box image on Alpine Linux.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# References:
# https://github.com/SagerNet/sing-box
# https://github.com/fscarmen/Sing-box-image
# https://github.com/RayWangQvQ/sing-box-installer/blob/main/DIY.md
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

FROM alpine:latest

COPY . .

RUN set -ex \
        && apk update && apk upgrade \
        && apk add --no-cache --virtual .build-deps \
            tar \
            tzdata \
        && apk add --no-cache \
            ca-certificates \
            curl \
        && chmod +x docker-entrypoint.sh \
        && chmod +x build.sh && ./build.sh \
        && cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
        && echo "Asia/Shanghai" > /etc/timezone \
        && rm -f Dockerfile build.sh \
        && apk del .build-deps \
        && rm -rf /var/cache/apk/* /tmp/* \
        && ln -sf /dev/stdout /var/log/sing-box/access.log

ENTRYPOINT [ "/docker-entrypoint.sh" ]