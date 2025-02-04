# Description: Dockerfile for creating a containerized solution for automated DanmakuRender video recording.
#
# Copyright (C) 2024 - 2025 honeok <honeok@duck.com>
#
# References:
# https://github.com/SmallPeaches/DanmakuRender
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

FROM python:3.9.20-alpine3.20

WORKDIR /DanmakuRender

COPY . .

RUN set -ex \
        && apk update \
        && apk add --no-cache curl git nodejs ffmpeg npm rust cargo \
        && chmod +x build.sh && ./build.sh \
        && python3 -m pip install --no-cache-dir -r requirements.txt \
        && install -m 755 docker-entrypoint.sh /docker-entrypoint.sh \
        && rm -fv build.sh docker-entrypoint.sh \
        && rm -rf configs_temp && mkdir -pv configs_temp \
        && apk del curl git rust cargo \
        && cp -frv configs/* configs_temp/ \
        && rm -rfv /var/cache/apk/*

ENTRYPOINT [ "/docker-entrypoint.sh" ]