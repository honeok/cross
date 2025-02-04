# Description: Dockerfile to build Sing-box image on Alpine Linux
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# References:
# https://github.com/SagerNet/sing-box
# https://github.com/fscarmen/Sing-box-image
#
# License Information:
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License, version 3 or later.
#
# This program is distributed WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <https://www.gnu.org/licenses/>.

FROM alpine:latest

COPY . .

RUN set -ex \
        && apk update && apk upgrade \
        && apk add --no-cache curl tar iproute2 tzdata ca-certificates \
        && chmod +x build.sh && ./build.sh \
        && apk del curl tar \
        && rm -rfv /var/cache/apk/* /var/log/*

ENTRYPOINT [ "/usr/local/bin/sing-box" ]