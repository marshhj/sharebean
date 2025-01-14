#!/bin/bash

download_file_if_not_exists() {
    local file="$1"
    local url="$2"
    if [ ! -f "$file" ]; then
        echo "Downloading $file..."
        curl -L -o "$file" "$url"
    else
        echo "$file already exists."
    fi
}

download_file_if_not_exists "redbean" "https://redbean.dev/redbean-3.0.0.com"
download_file_if_not_exists "zip" "https://cosmo.zip/pub/cosmos/bin/zip"

cp redbean sharebean
./zip -r sharebean ".init.lua" ".lua/" "app/"