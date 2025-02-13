# Description: Dockerfile to build a lightweight Sing-box image on Alpine Linux.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# References:
# https://github.com/SagerNet/sing-box
# https://github.com/fscarmen/Sing-box-image
# https://github.com/RayWangQvQ/sing-box-installer/blob/main/DIY.md
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License, version 3 or later.
#
# This program is distributed WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# See the LICENSE file or <https://www.gnu.org/licenses/> for full license terms.

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