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

FROM golang:1-bookworm AS builder

WORKDIR /go/src/github.com/FranzKafkaYu/x-ui

RUN set -ex \
        && apt-get update \
        && apt-get install -y git \
        && git clone --branch main --single-branch https://github.com/FranzKafkaYu/x-ui.git . \
        && go build -o /go/bin/x-ui main.go

FROM debian:bookworm-slim

RUN set -ex \
        && apt-get update && apt-get -y full-upgrade \
        && apt-get install -y ca-certificates \
        && rm -rfv /var/lib/apt/lists/* /var/log/*

WORKDIR /

COPY --from=builder /go/bin/x-ui /usr/local/bin/x-ui
COPY --from=builder /go/src/github.com/FranzKafkaYu/x-ui/bin/ /usr/local/bin/

VOLUME [ "/etc/x-ui" ]

EXPOSE 54321

ENTRYPOINT [ "/usr/local/bin/x-ui" ]