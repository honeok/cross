#!/bin/sh

if [ "$#" -eq 0 ]; then
    exec python3 -u main.py
else
    exec python3 -u main.py "$@"
fi