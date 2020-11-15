#!/bin/bash

# Download check_version, which is needed for making config files.

set -eu

# To specify a certain version of check_version, set CHECK_VERSION_TAG=vX.Y.Z
CHECK_VERSION_TAG="${CHECK_VERSION_TAG:-}"
PREFIX=$PREFIX

if [ -n "$CHECK_VERSION_TAG" ]; then
    RELEASE_API_URL="https://api.github.com/repos/akselsjogren/check_version/releases/tags/$CHECK_VERSION_TAG"
else
    RELEASE_API_URL="https://api.github.com/repos/akselsjogren/check_version/releases/latest"
fi

# Find download URL for the selected release
jsonfile=$(mktemp)
curl -s $RELEASE_API_URL -o $jsonfile
URL=$(cat <<EOF | python -
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

echo "Latest release: $URL"

SCRIPT_DIR="$( (cd "$(dirname "$0")"; pwd) )"

download_archive()
{
    if type curl &> /dev/null; then
        curl -s -L -O "$URL"
        return $?
    fi
    if type wget &> /dev/null; then
        wget -q "$URL"
        return $?
    fi
    echo "No download tool available"
    return 1
}

filename="$(basename "$URL")"
if [ -e "$filename" ]; then
    echo "Already got an archive: $filename"
else
    echo "Downloading $URL"
    download_archive
fi

test -e "$filename"
dir=$(basename "$filename" ".tar.gz")
if [ -e "$dir" ]; then
    rm -vrf ./"$dir"
fi

tar -xzf "$filename"
cd "$dir"
./configure --prefix="$PREFIX"
make
make install
rm -vrf ./"$dir"
