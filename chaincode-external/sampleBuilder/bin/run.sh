#!/bin/sh

# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

if [ "$#" -ne 2 ]; then
    >&2 echo "Expected 2 directories got $#"
    exit 1
fi

OUTPUT=$1
ARTIFACTS=$2

# shellcheck disable=SC2155
export CORE_CHAINCODE_ID_NAME="$(jq -r .chaincode_id "$ARTIFACTS/chaincode.json")"
export CORE_PEER_TLS_ENABLED="true"
export CORE_TLS_CLIENT_CERT_FILE="$ARTIFACTS/client.crt"
export CORE_TLS_CLIENT_KEY_FILE="$ARTIFACTS/client.key"
export CORE_PEER_TLS_ROOTCERT_FILE="$ARTIFACTS/root.crt"
export CORE_PEER_LOCALMSPID="$(jq -r .mspid "$ARTIFACTS/chaincode.json")"

jq -r .client_cert "$ARTIFACTS/chaincode.json" > "$CORE_TLS_CLIENT_CERT_FILE"
jq -r .client_key  "$ARTIFACTS/chaincode.json" > "$CORE_TLS_CLIENT_KEY_FILE"
jq -r .root_cert   "$ARTIFACTS/chaincode.json" > "$CORE_PEER_TLS_ROOTCERT_FILE"

if [ -z "$(jq -r .client_cert "$ARTIFACTS/chaincode.json")" ]; then
    export CORE_PEER_TLS_ENABLED="false"
fi

exec "$OUTPUT/chaincode" -peer.address="$(jq -r .peer_address "$ARTIFACTS/chaincode.json")"