#!/bin/bash

# installChaincode PEER ORG
function installChaincode() {
  ORG=dyno
  setGlobals $ORG
  set -x
  peer lifecycle chaincode queryinstalled --output json | jq -r 'try (.installed_chaincodes[].package_id)' | grep ^${PACKAGE_ID}$ >&log.txt
  if test $? -ne 0; then
    peer lifecycle chaincode install ${CC_NAME}.tar.gz >&log.txt
    res=$?
  fi
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode installation on peer0.dyno has failed"
  successln "Chaincode is installed on peer0.org"
}

# queryInstalled PEER ORG
function queryInstalled() {
  ORG=dyno
  setGlobals $ORG
  set -x
  peer lifecycle chaincode queryinstalled --output json | jq -r 'try (.installed_chaincodes[].package_id)' | grep ^${PACKAGE_ID}$ >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Query installed on peer0.org${ORG} has failed"
  successln "Query installed successful on peer0.org${ORG} on channel"
}

# approveForMyOrg VERSION PEER ORG
function approveForMyOrg() {
}

# checkCommitReadiness VERSION PEER ORG
function checkCommitReadiness() {
}

# commitChaincodeDefinition VERSION PEER ORG (PEER ORG)...
function commitChaincodeDefinition() {
}

# queryCommitted ORG
function queryCommitted() {
}

function chaincodeInvokeInit() {
}

function chaincodeQuery() {
}

function resolveSequence() {
}

#. scripts/envVar.sh

queryInstalledOnPeer() {
}

queryCommittedOnChannel() {
}

## Function to list chaincodes installed on the peer and committed chaincode visible to the org
listAllCommitted() {
}

chaincodeInvoke() {
}

chaincodeQuery() {
}