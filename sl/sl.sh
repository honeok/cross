#!/usr/bin/env sh

apt-get update
apt-get install -y libncurses5-dev libncursesw5-dev

gcc sl.c -o sl -lncurses