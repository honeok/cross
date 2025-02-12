# Description: Dockerfile for setting up a Key Management Service server.
#
# Copyright (C) 2025 honeok <honeok@duck.com>
# Copyright (C) 2018 - 2024 Teddysun <i@teddysun.com>
#
# References:
# https://github.com/Wind4/vlmcsd
# https://github.com/teddysun/across/blob/master/docker/kms/Dockerfile
# https://github.com/Wind4/vlmcsd-docker/blob/4195d04f687973a514e3fb663bd87161afd46697/Dockerfile
#
# Microsoft KMS Activation:
# https://wind4.github.io/vlmcsd
# https://learn.microsoft.com/zh-cn/windows-server/get-started/kms-client-activation-keys
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
        && apk update && apk upgrade \
        && apk add --no-cache \
            build-base \
            git \
            make \
        && git clone --branch master --single-branch https://github.com/Wind4/vlmcsd.git \
        && cd vlmcsd \
        && make

FROM alpine:latest

COPY --from=builder /usr/local/src/vlmcsd/bin/vlmcsd /usr/bin/vlmcsd

EXPOSE 1688

CMD [ "/usr/bin/vlmcsd", "-D", "-e" ]