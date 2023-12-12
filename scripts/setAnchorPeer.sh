#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# import utils
. scripts/envVar.sh
. scripts/configUpdate.sh
. scripts/scriptUtils.sh

# NOTE: this must be run in a CLI container since it requires jq and configtxlator 
createAnchorPeerUpdate() {
  infoln "Fetching channel config for channel mychannel"
  CHANNEL_NAME=mychannel

  fetchChannelConfig dyno mychannel dynoConfig.json

  infoln "Generating anchor peer update transaction for Org dyno on channel mychannel"

    HOST=peer0.dyno.example.com
    PORT=7051

    HOST=peer1.dyno.example.com
    PORT=7061

    HOST=peer0.dyno.example.com
    PORT=7071

  # Modify the configuration to append the anchor peer 
  jq '.channel_group.groups.Application.groups.DynoMSP.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'$HOST'","port": '$PORT'}]},"version": "0"}}' dynoConfig.json > dynoModified_config.json
  { set +x; } 2>/dev/null

  # Compute a config update, based on the differences between 
  # {orgmsp}config.json and {orgmsp}modified_config.json, write
  # it as a transaction to {orgmsp}anchors.tx
  createConfigUpdate mychannel dynoConfig.json dynoModified_config.json dynoAnchors.tx
}

updateAnchorPeer() {

  infoln "update anchor peer update transaction for dyno on channel mychannel"

  peer channel update -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com -c mychannel -f dynoAnchors.tx --tls --cafile "$ORDERER_CA" >&log.txt
  res=$?
  cat log.txt
  verifyResult $res "Anchor peer update failed"
  successln "Anchor peer set for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME'"
}

createAnchorPeerUpdate 

updateAnchorPeer 