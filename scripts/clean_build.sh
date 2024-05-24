#!/bin/bash

set -xe

pushd $(dirname "${BASH_SOURCE[0]}")/..
echo $(pwd)

echo "Removing Zig cache and output..."
rm -rf zig-cache zig-out

echo "Building module..."
zig build

echo "Building docs..."
zig build docs

popd
