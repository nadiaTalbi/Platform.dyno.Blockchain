#!/bin/sh

# Copyright IBM Corp. All Rights Reserved.
# 
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

if [ "$#" -ne 2 ]; then
    >&2 echo "Expected 2 directories got $#"
    exit 2
fi

>&2 jq . "$2/metadata.json"

if [ "$(jq -r .type "$2/metadata.json" | tr '[:upper:]' '[:lower:]')" != "golang" ]; then
    >&2 echo "only golang chaincode supported"
    exit 1
fi