#!/bin/sh

# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

if [ "$#" -ne 2 ]; then
    >&2 echo "Expected 2 directories got $#"
    exit 2
fi


BLD="$1"
RELEASE="$2"

if [ -d "$BLD/META-INF" ] ; then
   cp -a "$BLD/META-INF"/* "$RELEASE"
fi