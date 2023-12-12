#!/bin/bash

# imports  
. scripts/envVar.sh
. scripts/scriptUtils.sh


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
	configtxgen -profile ChannelUsingRaft  -outputBlock ./channel-artifacts/mychannel.block -channelID mychannel

	res=$?
	{ set +x; } 2>/dev/null
  verifyResult $res "Failed to generate channel configuration transaction..."
}

createChannel() {
	. scripts/orderer.sh mychannel > /dev/null 2>&1
	docker restart $(docker ps -q)
	cat log.txt
	verifyResult $res "Channel creation failed"
}

# joinChannel ORG
joinChannel() {
  	FABRIC_CFG_PATH=${PWD}/compose/docker/peercfg
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt 5 ] ; do
	set -x
	peer channel join -b ${PWD}/channel-artifacts/mychannel.block >&log.txt
	res=$?
    { set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	peer channel list
	
	cat log.txt

	verifyResult $res "After 5 attempts, peer0.dyno has failed to join channel 'mychannel' "
}

setAnchorPeer() {
  ${CONTAINER_CLI} exec cli ./scripts/setAnchorPeer.sh mychannel
}


## Create channel genesis block
FABRIC_CFG_PATH=$PWD/compose/docker/peercfg
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

# Set the anchor peers for each org in the channel
infoln "Setting anchor peer for org1..."
setAnchorPeer 

successln "Channel '$CHANNEL_NAME' joined"