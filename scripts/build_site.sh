#!/bin/bash

set -xe

# Exit if quarto is not installed
if ! command -v quarto &> /dev/null
then
    echo "The docs are built using quarto, which could not be found"
    exit 1
fi

pushd $(dirname "${BASH_SOURCE[0]}")/../docs
pwd

quarto render index.qmd --to html --toc

popd