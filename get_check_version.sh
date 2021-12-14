#!/bin/bash

# Download check_version, which is needed for making config files.

set -eu

trap 'echo Warning: command failed at line $LINENO' ERR

# To specify a certain version of check_version, set CHECK_VERSION_TAG=vX.Y.Z
CHECK_VERSION_TAG="${CHECK_VERSION_TAG:-}"
PREFIX=$PREFIX
BIN_RELEASE_FALLBACK="https://github.com/akselsjogren/check_version/releases/download/v0.2.1/check_version-0.2.1-$(arch).tar.gz"

if [ -n "$CHECK_VERSION_TAG" ]; then
    RELEASE_API_URL="https://api.github.com/repos/akselsjogren/check_version/releases/tags/$CHECK_VERSION_TAG"
else
    RELEASE_API_URL="https://api.github.com/repos/akselsjogren/check_version/releases/latest"
fi

log() {
	echo $* >&2
}

# Find download URL for the selected release
jsonfile=$(mktemp)
curl -s $RELEASE_API_URL -o $jsonfile
URL=$(cat <<EOF | python3 -
import json,sys
with open("$jsonfile", "r") as f:
    data = json.load(f)
try:
    print(data["assets"][0]["browser_download_url"])
except IndexError:
    sys.stderr.write("No assets found for %r" % data["html_url"])
    sys.exit(1)
EOF
)
rm $jsonfile

log "Latest release: $URL"

SCRIPT_DIR="$( (cd "$(dirname "$0")"; pwd) )"

download_archive()
{
	filename="$(basename "$1")"
	if [ -e "$filename" ]; then
		log "Already got an archive: $filename"
		return 0
	fi
	log "Downloading $1"
    if type curl &> /dev/null; then
        curl -sSL --fail -O "$1"
        return $?
    fi
    if type wget &> /dev/null; then
        wget -q "$1"
        return $?
    fi
    log "No download tool available"
    return 1
}

get_release()
{
	set -e
	download_archive "$1"
	filename="$(basename "$1")"
	test -e "$filename"
	dir=$(tar -tzf "$filename" | head -1 | sed -e 's%/*$%%')
	if [ -e "$dir" ]; then
		rm -rf ./"$dir"
	fi
	tar -xzf "$filename"
	echo "$dir"
}

dir=$(get_release "$URL")

pushd "$dir"
set +e
./configure --prefix="$PREFIX"
ret=$?
set -e
if [ $ret -eq 0 ]; then
	make
	make install
	popd
	rm -rf ./"$dir"
	exit 0
fi

# configure failed, fallback to install old binary release.
popd
log "Failed to build from source, falling back to binary release $BIN_RELEASE_FALLBACK"
rm -rf ./"$dir"
if type check_version 2> /dev/null; then
	log "Using already installed check_version"
	exit 0
fi
dir=$(get_release "$BIN_RELEASE_FALLBACK")
install -v -D "$dir/check_version" "$PREFIX/bin/check_version"
rm -rf ./"$dir"
