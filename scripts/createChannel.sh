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
  setGlobals dyno 0
	which configtxgen
	if [ "$?" -ne 0 ]; then
		fatalln "configtxgen tool not found."
	fi
	set -x
	configtxgen -profile TwoOrgsApplicationGenesis  -outputBlock ./channel-artifacts/mychannel.block -channelID mychannel

	res=$?
	{ set +x; } 2>/dev/null
  verifyResult $res "Failed to generate channel configuration transaction..."
}

createChannel() {
	. scripts/orderer.sh mychannel > /dev/null 2>&1
	# docker restart $(docker ps -q)
	cat log.txt
	verifyResult $res "Channel creation failed"
}

# joinChannel ORG
joinChannel() {
  	FABRIC_CFG_PATH=${PWD}/compose/docker/peercfg
	local rc=1
	local COUNTER=1
	PEER=$1
	## Sometimes Join takes time, hence retry
	setGlobalsWithAdminKeys dyno $PEER
	while [ $rc -ne 0 -a $COUNTER -lt 5 ] ; do
	set -x
	peer channel list

	peer channel join -b ${PWD}/channel-artifacts/mychannel.block >&log.txt
	res=$?
    { set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt

	verifyResult $res "After 5 attempts, peer0.dyno has failed to join channel 'mychannel' "
}

setAnchorPeer() {
  ${CONTAINER_CLI} exec cli ./scripts/setAnchorPeer.sh mychannel
}


## Create channel genesis block


infoln "Generating channel genesis block '${CHANNEL_NAME}.block'"
FABRIC_CFG_PATH=${PWD}/configtx
createChannelGenesisBlock

FABRIC_CFG_PATH=$PWD/compose/docker/peercfg
BLOCKFILE="./channel-artifacts/genesis.block"


## Create channel
infoln "Creating channel ${CHANNEL_NAME}"
createChannel 
successln "Channel '$CHANNEL_NAME' created"

cp -r ${PWD}/organizations/peerOrganizations/dyno.example.com/peers/* ${PWD}/organizations/peerOrganizations/dyno.example.com/users/

## Join all the peers to the channel
infoln "Joining peer 0 to the channel..."
joinChannel 0
infoln "Joining peer 1  to the channel..."
joinChannel 1
infoln "Joining peer 2 to the channel..."
joinChannel 2

# Set the anchor peers for each org in the channel
infoln "Setting anchor peer for dyno..."
setAnchorPeer 

successln "Channel '$CHANNEL_NAME' joined"