# Description: Dockerfile for building a container for FranzKafkaYu x-ui
#
# Copyright (C) 2025 honeok <honeok@duck.com>
#
# References:
# https://github.com/FranzKafkaYu/x-ui
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

FROM golang:alpine AS builder

WORKDIR /go/src

RUN set -ex \
    && apk update && apk add --no-cache git \
    && git clone https://github.com/FranzKafkaYu/x-ui.git . \
    && go build main.go

FROM alpine:latest

RUN set -ex \
    && apk update && apk add --no-cache ca-certificates \
    && rm -rfv /var/cache/apk/*

WORKDIR /

COPY --from=builder /go/src/main /usr/local/bin/x-ui
COPY --from=builder /go/src/bin/ /usr/local/bin/

VOLUME [ "/etc/x-ui" ]

CMD [ "/usr/local/bin/x-ui" ]