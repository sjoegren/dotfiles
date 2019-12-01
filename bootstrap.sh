#!/bin/bash

# Download check_version, which is needed for making config files.

set -eu

# Find download URL for the latest release
LATEST_RELEASE_URL="https://api.github.com/repos/akselsjogren/check_version/releases/latest"
jsonfile=$(mktemp)
curl -s $LATEST_RELEASE_URL -o $jsonfile
URL=$(cat <<EOF | python -
import json
with open("$jsonfile", "r") as f:
    data = json.load(f)
print(data["assets"][0]["browser_download_url"])
EOF
)
rm $jsonfile

echo "Latest release: $URL"

SCRIPT_DIR="$( (cd "$(dirname "$0")"; pwd) )"
TARGET_DIR="$SCRIPT_DIR/bin"

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
dir=$(basename "$filename" .tar.gz)
if [ -e "$dir" ]; then
    rm -vrf ./"$dir"
fi

tar -xzvf "$filename"
mv -vf "$dir/check_version" "$TARGET_DIR/"
rm -vrf ./"$dir"
