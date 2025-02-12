# Description: Dockerfile for creating a containerized solution for automated DanmakuRender video recording.
#
# Copyright (C) 2024 - 2025 honeok <honeok@duck.com>
#
# References:
# https://github.com/SmallPeaches/DanmakuRender
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License, version 3 or later.
#
# This program is distributed WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# See the LICENSE file or <https://www.gnu.org/licenses/> for full license terms.

FROM python:3.9.20-slim-bookworm

WORKDIR /DanmakuRender

COPY . .

RUN set -ex \
        && apt-get update \
        && apt-get -y install \
            curl \
            ffmpeg \
            git \
            nodejs \
            npm \
        && chmod +x build.sh && ./build.sh \
        && python3 -m pip install --no-cache-dir -r requirements.txt \
        && install -m 755 docker-entrypoint.sh /docker-entrypoint.sh \
        && rm -f Dockerfile build.sh docker-entrypoint.sh docker-compose.yml \
        && rm -rf configs_temp \
        && mkdir -p configs_temp \
        && apt-get -y remove --purge \
            curl \
            git \
        && apt-get clean \
        && cp -rf configs/* configs_temp/ \
        && rm -rf /var/lib/apt/lists/* /var/log/* /tmp/*

ENTRYPOINT [ "/docker-entrypoint.sh" ]