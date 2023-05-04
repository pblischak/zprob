#!/bin/bash

echo "Removing Zig cache and output..."
rm -rf zig-cache zig-out 

echo "Building and running module tests..."
zig build test