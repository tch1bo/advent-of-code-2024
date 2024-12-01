#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "please provide one arg"
    exit 1
fi

mkdir "$1"
cd "$1"
zig init
rm -rf "src/root.zig"
