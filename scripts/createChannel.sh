#!/bin/bash

# imports  
. scripts/envVar.sh
. ../scriptUtils.sh


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

if [ ! -d "channel-artifacts" ]; then
	mkdir channel-artifacts
fi

# Generate orderer system channle genesis block
createChannelGenesisBlock() {
  setGlobals 1
	which configtxgen
	if [ "$?" -ne 0 ]; then
		fatalln "configtxgen tool not found."
	fi
	set -x
    configtxgen -profile OrgsOrdererGenesis -outputBlock ./system-genesis-block/genesis.block -channelID $CHANNEL_NAME

	res=$?
	{ set +x; } 2>/dev/null
    verifyResult $res "Failed to generate channel configuration transaction..."
}

createChannel() {
	local rc=1
	local COUNTER=1
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
        #. scripts/orderer.sh ${CHANNEL_NAME}> /dev/null 2>&1
        peer channel create -o localhost:1100 -c $CHANNEL_NAME --orderetTLSHostnameOverride  config.orderers -f ./channel-artifacts/${CHANNEL_NAME}.tx --outputBlock -outputBlock ./system-genesis-block/genesis.block
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Channel creation failed"
}

# joinChannel ORG
joinChannel() {
  FABRIC_CFG_PATH=$PWD/../config/
  setGlobals $ORG
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
    peer channel join -b $BLOCKFILE >&log.txt
    res=$?
    { set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "After $MAX_RETRY attempts, peer0.org has failed to join channel '$CHANNEL_NAME' "
}

setAnchorPeer() {
  ${CONTAINER_CLI} exec cli ./scripts/setAnchorPeer.sh $CHANNEL_NAME 
}



## Create channel genesis block
FABRIC_CFG_PATH=$PWD/../config/
BLOCKFILE="./channel-artifacts/${CHANNEL_NAME}.block"

infoln "Generating channel genesis block '${CHANNEL_NAME}.block'"
FABRIC_CFG_PATH=${PWD}/configtx


createChannelGenesisBlock


## Create channel
infoln "Creating channel ${CHANNEL_NAME}"
createChannel $BFT
successln "Channel '$CHANNEL_NAME' created"

## Join all the peers to the channel
infoln "Joining org1 peer to the channel..."
joinChannel 

## Set the anchor peers for each org in the channel
infoln "Setting anchor peer for org1..."
setAnchorPeer 

successln "Channel '$CHANNEL_NAME' joined"