# Dockerfile for DanmakuRender automation
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# Reference:
# https://github.com/SmallPeaches/DanmakuRender

FROM python:3.9.21-alpine3.21

WORKDIR /DanmakuRender

COPY . .

RUN set -ex \
    && apk add --no-cache curl nodejs ffmpeg npm rust cargo \
    && curl -O -L https://github.com/biliup/biliup-rs/releases/download/v0.2.1/biliupR-v0.2.1-x86_64-linux.tar.xz \
    && tar -xf biliupR-v0.2.1-x86_64-linux.tar.xz \
    && mv biliupR-v0.2.1-x86_64-linux/biliup tools/ \
    && pip install -r requirements.txt \
    && apk del curl rust cargo \
    && rm -rf biliupR-* /var/cache/apk/*

ENTRYPOINT ["python3", "-u", "main.py"]