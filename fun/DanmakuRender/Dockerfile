# Description: Dockerfile for creating a containerized solution for automated DanmakuRender video recording.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
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
    && apk update && apk add --no-cache curl git nodejs ffmpeg npm rust cargo \
    && chmod +x build.sh && ./build.sh \
    && pip install -r requirements.txt \
    && apk del curl git rust cargo \
    && rm -rfv /var/cache/apk/*

ENTRYPOINT ["python3", "-u", "main.py"]