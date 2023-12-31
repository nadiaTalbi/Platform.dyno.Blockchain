#!/bin/sh

# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

if [ "$#" -ne 3 ]; then
    >&2 echo "Expected 3 directories got $#"
    exit 1
fi

SOURCE=$1
METADATA=$2
OUTPUT=$3

>&2 jq . "$2/metadata.json"

if [[ "$(jq -r .label "$METADATA/metadata.json")" == *fail* ]]; then
    >&2 echo "Exiting with failure..."
    exit 1
fi

GO_PACKAGE_PATH="$(jq -r .path "$METADATA/metadata.json")"
if [ -f "$SOURCE/src/go.mod" ]; then
    cd "$SOURCE/src"
    go build -v -mod=readonly -o "$OUTPUT/chaincode" "$GO_PACKAGE_PATH"
else
    GO111MODULE=off go build -v  -o "$OUTPUT/chaincode" "$GO_PACKAGE_PATH"
fi

# copy index metadata if present
if [ -d "$SOURCE/META-INF" ]; then
    cp -a "$SOURCE/META-INF" "$OUTPUT"
fi