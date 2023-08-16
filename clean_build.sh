#!/bin/bash

echo "Removing Zig cache and output..."
rm -rf zig-cache zig-out

echo "Building module..."
zig build

echo "Building docs..."
zig build docs
cp -R zig-out/docs docs