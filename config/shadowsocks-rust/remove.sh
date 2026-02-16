#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0
#
# Description: The script is used to remove shadowsocks-rust from the system, cleanup its service, configurations and executables.
# Copyright (c) 2026 honeok <i@honeok.com>

set -eE

WORK_DIR="/etc/shadowsocks-rust"
SERVICE_DIR="/etc/systemd/system/shadowsocks.service"
BINARY_NAME=(
    "sslocal"
    "ssmanager"
    "ssserver"
    "ssservice"
    "ssurl"
)

systemctl disable --now shadowsocks.service

[ ! -d "$WORK_DIR" ] || rm -rf "$WORK_DIR" > /dev/null 2>&1
[ ! -f "$SERVICE_DIR" ] || rm -f "$SERVICE_DIR" > /dev/null 2>&1

for b in "${BINARY_NAME[@]}"; do
    which "$b" > /dev/null 2>&1 && rm -f "$(which "$b")" > /dev/null 2>&1
done
