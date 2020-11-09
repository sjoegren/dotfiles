#!/bin/bash
set -eu

prefix="$1"

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${BASEDIR}"

if ! type -p autoreconf > /dev/null; then
	echo "WARNING: need autotools to install utils" >&2
	exit 0
fi

autoreconf --install --symlink
./configure --prefix="$prefix"
make
make install
make clean
