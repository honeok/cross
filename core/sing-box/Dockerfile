# Description: build a lightweight sing-box image on alpine linux.
#
# Copyright (c) 2025 honeok <honeok@duck.com>
#
# References:
# https://github.com/SagerNet/sing-box
# https://github.com/fscarmen/Sing-box-image
# https://github.com/RayWangQvQ/sing-box-installer
#
# Licensed under the GNU General Public License, version 2 only.
# This program is distributed WITHOUT ANY WARRANTY.
# See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

FROM alpine:latest

ARG VERSION

COPY build.sh .
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN set -ex \
        && apk update && apk upgrade \
        && apk add --no-cache \
            ca-certificates \
            tzdata \
        && chmod +x /docker-entrypoint.sh build.sh \
        && ./build.sh ${VERSION} && rm -f build.sh \
        && rm -rf /var/cache/apk/* /tmp/* \
        && ln -sf /dev/stdout /var/log/sing-box/access.log

ENV TZ=Asia/Shanghai

CMD [ "/docker-entrypoint.sh" ]