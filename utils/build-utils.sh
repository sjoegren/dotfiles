#!/bin/bash
set -eu

prefix="$1"

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${BASEDIR}"

autoreconf --install --symlink
./configure --prefix="$prefix"
make
make install
make clean
