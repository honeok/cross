#!/usr/bin/env sh
#
# Description: This script is used to build the v2ray docker image and configure the basic operating environment.
#
# Copyright (c) 2025 honeok <honeok@disroot.org>
#
# SPDX-License-Identifier: GPL-2.0-only

set -ex

V2RAY_LTAG="$1"

if ! git clone --depth=1 --branch "$V2RAY_LTAG" https://github.com/v2fly/v2ray-core.git v2ray; then
    printf 'Error: Failed to clone the project branch.\n' >&2; exit 1
fi

cd v2ray || { printf 'Error: permission denied or directory does not exist\n' >&2; exit 1; }

EXTRA_ARG=""
case "$(go env GOOS)-$(go env GOARCH)" in
    linux-amd64|linux-arm64)
        EXTRA_ARG="-buildmode=pie"
    ;;
esac

if [ -n "$EXTRA_ARG" ]; then
    go build "$EXTRA_ARG" -v -trimpath -ldflags "-s -w -buildid=" -o /go/bin/v2ray ./main
else
    go build -v -trimpath -ldflags "-s -w -buildid=" -o /go/bin/v2ray ./main
fi