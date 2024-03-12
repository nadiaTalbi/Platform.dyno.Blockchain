
#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This is a collection of bash functions used by different scripts

# imports
. scripts/scriptUtils.sh

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=./organizations/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem
export PEER0_DYNO_CA=./organizations/peerOrganizations/dyno.example.com/tlsca/tlsca.dyno.example.com-cert.pem
export ORDERER_ADMIN_TLS_SIGN_CERT=./organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATE_KEY=./organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key


setGlobalsWithAdminKeys() {
    echo "org $1 peer $2"
  local USING_ORG=$1
  local USING_PEER=$2

  infoln "Using organization ${USING_ORG}"
  export CORE_PEER_LOCALMSPID="DynoMSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_DYNO_CA
  export CORE_PEER_MSPCONFIGPATH=./organizations/peerOrganizations/dyno.example.com/users/Admin@dyno.example.com/msp
  
  if [ $USING_PEER -eq 0 ]; then
    export CORE_PEER_ADDRESS=localhost:7051
  elif [ $USING_PEER -eq 1 ]; then
    export CORE_PEER_ADDRESS=localhost:7061
  elif [ $USING_PEER -eq 2 ]; then
    export CORE_PEER_ADDRESS=localhost:7071
  fi

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}


setGlobals() {
  echo "org $1"

  local USING_ORG=$1
  infoln "Using organization ${USING_ORG}"

  export CORE_PEER_MSPCONFIGPATH=./organizations/peerOrganizations/dyno.example.com/users/Admin@dyno.example.com/msp
  export CORE_PEER_LOCALMSPID="DynoMSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_DYNO_CA
  export CORE_PEER_ADDRESS=localhost:7051
    
  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi

}



# Set environment variables for use in the CLI container
setGlobalsCLI() {
  export CORE_PEER_ADDRESS=peer0.dyno.example.com:7051
}

# parsePeerConnectionParameters $@
# Helper function that sets the peer connection parameters for a chaincode
# operation
parsePeerConnectionParameters() {
  PEER_CONN_PARMS=()
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals dyno $1
    PEER="peer0.dyno"
    ## Set peer addresses
    if [ -z "$PEERS" ]
    then
	PEERS="$PEER"
    else
	PEERS="$PEERS $PEER"
    fi
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $CORE_PEER_ADDRESS)
    ## Set path to TLS certificate
    CA=$PEER0_DYNO_CA
    TLSINFO=(--tlsRootCertFiles "${!CA}")
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" "${TLSINFO[@]}")
    # shift by one to get to the next organization
    shift
  done
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}