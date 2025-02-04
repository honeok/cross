# Description: Dockerfile for setting up a Key Management Service server
#
# Copyright (C) 2025 honeok <honeok@duck.com>
# Copyright (C) 2018 - 2024 Teddysun <i@teddysun.com>
#
# References:
# https://github.com/Wind4/vlmcsd
# https://wind4.github.io/vlmcsd
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

FROM alpine:latest AS builder

WORKDIR /usr/local/src

RUN set -ex \
        && apk update \
        && apk add --no-cache git make build-base \
        && git clone --branch master --single-branch https://github.com/Wind4/vlmcsd.git . \
        && make

FROM alpine:latest

COPY --from=builder /usr/local/src/bin/vlmcsd /usr/bin/vlmcsd

EXPOSE 1688/tcp

ENTRYPOINT [ "/usr/bin/vlmcsd" ]

CMD [ "-D", "-e" ]