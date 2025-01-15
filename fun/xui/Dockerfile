# Dockerfile for building a container for FranzKafkaYu x-ui
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# Repository and reference:
# https://github.com/FranzKafkaYu/x-ui

FROM alpine:latest

LABEL maintainer="honeok <honeok@duck.com>"

WORKDIR /x-ui

RUN set -ex \
    && apk add --no-cache curl tar jq bash \
    && curl -Lk -O https://github.com/FranzKafkaYu/x-ui/releases/download/0.3.4.4/x-ui-linux-amd64.tar.gz \
    && tar --strip-components=1 -xvf x-ui-linux-amd64.tar.gz -C . \
    && rm -f x-ui-linux-amd64.tar.gz \
    && chmod +x x-ui bin/xray-linux-amd64 \
    && curl -L -o /usr/bin/x-ui https://raw.githubusercontent.com/FranzKafkaYu/x-ui/main/x-ui.sh \
    && chmod +x x-ui.sh /usr/bin/x-ui