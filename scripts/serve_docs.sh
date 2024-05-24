#!/bin/bash

set -xe

pushd $(dirname "${BASH_SOURCE[0]}")/..
echo $(pwd)

python3 -m http.server -b localhost 8080 -d zig-out/docs/

popd
