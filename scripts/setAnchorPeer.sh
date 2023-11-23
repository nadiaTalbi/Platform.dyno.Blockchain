#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# import utils
. scripts/envVar.sh
. scripts/configUpdate.sh


createAnchorPeerUpdate() {
}

updateAnchorPeer() {
}

CHANNEL_NAME=$1

setGlobalsCLI 

createAnchorPeerUpdate 

updateAnchorPeer 