#!/bin/bash

# imports  
. scripts/envVar.sh
. scriptUtils.sh


CHANNEL_NAME="$1"
DELAY="$2"
MAX_RETRY="$3"
VERBOSE="$4"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}

: ${CONTAINER_CLI:="docker"}
: ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI}-compose"}
infoln "Using ${CONTAINER_CLI} and ${CONTAINER_CLI_COMPOSE}"

#Create a Channel Cnfiguration Transaction
createChannelGenesisBlock() {
  setGlobals 1
	which configtxgen
	if [ "$?" -ne 0 ]; then
		fatalln "configtxgen tool not found."
	fi
	set -x
	configtxgen -profile OrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID mychannel

	res=$?
	{ set +x; } 2>/dev/null
  verifyResult $res "Failed to generate channel configuration transaction..."
}

createChannel() {
	local rc=1
	local COUNTER=1
	. scripts/orderer.sh mychannel > /dev/null 2>&1
	cat log.txt
	verifyResult $res "Channel creation failed"
}

# joinChannel ORG
joinChannel() {
  	FABRIC_CFG_PATH=${PWD}/config/
	peer channel join -b ./channel-artifacts/genesis.block >&log.txt
	cat log.txt
}

setAnchorPeer() {
  ${CONTAINER_CLI} exec cli ./scripts/setAnchorPeer.sh mychannel
}


## Create channel genesis block
FABRIC_CFG_PATH=$PWD/config/
BLOCKFILE="./channel-artifacts/genesis.block"

infoln "Generating channel genesis block '${CHANNEL_NAME}.block'"
FABRIC_CFG_PATH=${PWD}/configtx

createChannelGenesisBlock
## Create channel
infoln "Creating channel ${CHANNEL_NAME}"
createChannel 
successln "Channel '$CHANNEL_NAME' created"

## Join all the peers to the channel
infoln "Joining peer to the channel..."
joinChannel 

## Set the anchor peers for each org in the channel
infoln "Setting anchor peer for org1..."
setAnchorPeer 

successln "Channel '$CHANNEL_NAME' joined"