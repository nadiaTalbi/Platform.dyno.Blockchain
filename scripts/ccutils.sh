#!/bin/bash

# installChaincode PEER ORG
function installChaincode() {
  ORG=dyno
  # setGlobals $ORG

  local USING_PEER=$2

  infoln "Using organization ${USING_ORG}, $USING_PEER"
  setGlobalsWithAdminKeys dyno $USING_PEER

  set -x

  peer lifecycle chaincode queryinstalled --output json | jq -r 'try (.installed_chaincodes[].package_id)' | grep ^${PACKAGE_ID}$ >&log.txt
  if test $? -ne 0; then
    if [ $USING_PEER -eq 0 ]; then
      peer lifecycle chaincode install ${CC_NAME}.tar.gz --peerAddresses localhost:7051 --tlsRootCertFiles ./organizations/peerOrganizations/dyno.example.com/peers/peer0.dyno.example.com/tls/ca.crt >&log.txt
    elif [ $USING_PEER -eq 1 ]; then
      peer lifecycle chaincode install ${CC_NAME}.tar.gz --peerAddresses localhost:7061 --tlsRootCertFiles ./organizations/peerOrganizations/dyno.example.com/peers/peer1.dyno.example.com/tls/ca.crt >&log.txt
    elif [ $USING_PEER -eq 2 ]; then
      peer lifecycle chaincode install ${CC_NAME}.tar.gz --peerAddresses localhost:7071 --tlsRootCertFiles ./organizations/peerOrganizations/dyno.example.com/peers/peer2.dyno.example.com/tls/ca.crt >&log.txt
    fi
    res=$?
  fi
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode installation on peer${USING_PEER}.dyno has failed"
  successln "Chaincode is installed on peer${USING_PEER}.dyno"
}

# queryInstalled PEER ORG
function queryInstalled() {
  ORG=dyno
  local USING_PEER=$2
  # setGlobals $ORG
  infoln "Using organization ${USING_ORG}, $USING_PEER"
  setGlobalsWithAdminKeys dyno $USING_PEER
  set -x
  if [ $USING_PEER -eq 0 ]; then
    peer lifecycle chaincode queryinstalled --peerAddresses localhost:7051 --tlsRootCertFiles ./organizations/peerOrganizations/dyno.example.com/peers/peer0.dyno.example.com/tls/ca.crt --output json | jq -r 'try (.installed_chaincodes[].package_id)' | grep ^${PACKAGE_ID}$ >&log.txt 
  elif [ $USING_PEER -eq 1 ]; then
    peer lifecycle chaincode queryinstalled --peerAddresses localhost:7061 --tlsRootCertFiles ./organizations/peerOrganizations/dyno.example.com/peers/peer1.dyno.example.com/tls/ca.crt --output json | jq -r 'try (.installed_chaincodes[].package_id)' | grep ^${PACKAGE_ID}$ >&log.txt 
  elif [ $USING_PEER -eq 2 ]; then
    peer lifecycle chaincode queryinstalled --peerAddresses localhost:7071 --tlsRootCertFiles ./organizations/peerOrganizations/dyno.example.com/peers/peer2.dyno.example.com/tls/ca.crt --output json | jq -r 'try (.installed_chaincodes[].package_id)' | grep ^${PACKAGE_ID}$ >&log.txt 
  fi
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Query installed on peer$USING_PEER.${ORG} has failed"
  successln "Query installed successful on peer$USING_PEER.${ORG} on channel"
}

# approveForMyOrg VERSION PEER ORG
function approveForMyOrg() {
  ORG=dyno
  PEER=$1

  infoln "Approve my org $ORG , peer : $PEER"
  setGlobals $ORG
  set -x
  # --signature-policy "OR('DynoMSP.peer')"
  peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "./organizations/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem" --channelID $CHANNEL_NAME --name ${CC_NAME} --version 1.0 --init-required --package-id ${PACKAGE_ID} --sequence 1 >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode definition approved on peer0.org${ORG} on channel '$CHANNEL_NAME' failed"
  successln "Chaincode definition approved on ${ORG} on channel '$CHANNEL_NAME'"
}

# checkCommitReadiness VERSION PEER ORG
function checkCommitReadiness() {
  ORG=dyno
  shift 1

  setGlobals $ORG
  infoln "Checking the commit readiness of the chaincode definition on ${ORG} on channel $CHANNEL_NAME..."

  local rc=1
  local COUNTER=1
  # continue to poll
  # we either get a successful response, or reach MAX RETRY
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    infoln "Attempting to check the commit readiness of the chaincode definition on ${ORG}, Retry after $DELAY seconds."
    set -x
    peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name basic --version 1.0 --init-required --sequence 1 --output json >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    let rc=0
    for var in "$@"; do
      grep "$var" log.txt &>/dev/null || let rc=1
    done
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  if test $rc -eq 0; then
    infoln "Checking the commit readiness of the chaincode definition successful on dyno on channel mychannel"
  else
    fatalln "After $MAX_RETRY attempts, Check commit readiness result on ${ORG} is INVALID!"
  fi
}

# commitChaincodeDefinition VERSION PEER ORG (PEER ORG)...
function commitChaincodeDefinition() {

  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "
  set -x

  peer lifecycle chaincode commit \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile ./organizations/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem \
  --channelID mychannel \
  --name basic \
  --peerAddresses localhost:7051 --tlsRootCertFiles ./organizations/peerOrganizations/dyno.example.com/peers/peer0.dyno.example.com/tls/ca.crt \
  --peerAddresses localhost:7061 --tlsRootCertFiles ./organizations/peerOrganizations/dyno.example.com/peers/peer1.dyno.example.com/tls/ca.crt \
  --peerAddresses localhost:7071 --tlsRootCertFiles ./organizations/peerOrganizations/dyno.example.com/peers/peer2.dyno.example.com/tls/ca.crt \
  --version 1.0 --init-required \
  --sequence 1 \
  >&log.txt

  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode definition commit failed on peer0.org${ORG} on channel '$CHANNEL_NAME' failed"
  successln "Chaincode definition committed on channel '$CHANNEL_NAME'"
}

# queryCommitted ORG
function queryCommitted() {
   ORG=dyno
  setGlobals $ORG
  EXPECTED_RESULT="Version: 1.0, Sequence: 1, Endorsement Plugin: escc, Validation Plugin: vscc"
  infoln "Querying chaincode definition on peer0.${ORG} on channel '$CHANNEL_NAME', ${EXPECTED_RESULT}..."
  local rc=1
  local COUNTER=1
  # continue to poll
  # we either get a successful response, or reach MAX RETRY
  while [ $rc -ne 0 -a $COUNTER -lt 2 ]; do
    sleep $DELAY
    infoln "Attempting to Query committed status on peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME} >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    test $res -eq 0 && VALUE=$(cat log.txt | grep -o '^Version: 1.0, Sequence: [0-9]*, Endorsement Plugin: escc, Validation Plugin: vscc')
    infoln "Value : ${VALUE} , ExpectedValue = ${EXPECTED_RESULT}"
    test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
    COUNTER=$(expr $COUNTER + 1)
  done
  infoln "rc : ${rc}"
  if test $rc -eq 0; then
    successln "Query chaincode definition successful on peer0.org${ORG} on channel '$CHANNEL_NAME'"
  else
    fatalln "After $MAX_RETRY attempts, Query chaincode definition result on peer0.${ORG} is INVALID!"
  fi
}

function chaincodeInvokeInit() {
  # parsePeerConnectionParameters $@

  res=$?
  verifyResult $res "Invoke transaction failed on channel mychannel  due to uneven number of peer and org parameters "

  local rc=1
  local COUNTER=1
  local fcn_call='{"function":"InitLedger","Args":[]}'
  # continue to poll
  # we either get a successful response, or reach MAX RETRY
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    set -x
    infoln "invoke fcn call:${fcn_call}"
    peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "./organizations/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem" -C $CHANNEL_NAME -n ${CC_NAME} --peerAddresses localhost:7051 --tlsRootCertFiles ./organizations/peerOrganizations/dyno.example.com/peers/peer0.dyno.example.com/tls/ca.crt \
    --peerAddresses localhost:7061 --tlsRootCertFiles ./organizations/peerOrganizations/dyno.example.com/peers/peer1.dyno.example.com/tls/ca.crt \
    --peerAddresses localhost:7071 --tlsRootCertFiles ./organizations/peerOrganizations/dyno.example.com/peers/peer2.dyno.example.com/tls/ca.crt --isInit -c ${fcn_call} >&log.txt
    
    res=$?
    { set +x; } 2>/dev/null
    let rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done
  
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  successln "Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME'"
}

function chaincodeQuery() {
  ORG=dyno
  setGlobals $ORG
  infoln "Querying on peer0.org${ORG} on channel '$CHANNEL_NAME'..."
  local rc=1
  local COUNTER=1
  # continue to poll
  # we either get a successful response, or reach MAX RETRY
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    infoln "Attempting to Query peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"Args":["org.hyperledger.fabric:GetMetadata"]}' >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    let rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  if test $rc -eq 0; then
    successln "Query successful on peer0.org${ORG} on channel '$CHANNEL_NAME'"
  else
    fatalln "After $MAX_RETRY attempts, Query result on peer0.org${ORG} is INVALID!"
  fi
}

function resolveSequence() {
  #if the sequence is not "auto", then use the provided sequence
  if [[ "${CC_SEQUENCE}" != "auto" ]]; then
    return 0
  fi

  local rc=1
  local COUNTER=1
  # first, find the sequence number of the committed chaincode
  # we either get a successful response, or reach MAX RETRY
  while [ $rc -ne 0 -a $COUNTER -lt 5 ]; do
    set -x
    COMMITTED_CC_SEQUENCE=$(peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME} | sed -n "/Version:/{s/.*Sequence: //; s/, Endorsement Plugin:.*$//; p;}")
    res=$?
    { set +x; } 2>/dev/null
    let rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done

  # if there are no committed versions, then set the sequence to 1
  if [ -z $COMMITTED_CC_SEQUENCE ]; then
    CC_SEQUENCE=1
    return 0
  fi

  rc=1
  COUNTER=1
  # next, find the sequence number of the approved chaincode
  # we either get a successful response, or reach MAX RETRY
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    set -x
    APPROVED_CC_SEQUENCE=$(peer lifecycle chaincode queryapproved --channelID $CHANNEL_NAME --name ${CC_NAME} | sed -n "/sequence:/{s/^sequence: //; s/, version:.*$//; p;}")
    res=$?
    { set +x; } 2>/dev/null
    let rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done

  # if the committed sequence and the approved sequence match, then increment the sequence
  # otherwise, use the approved sequence
  if [ $COMMITTED_CC_SEQUENCE == $APPROVED_CC_SEQUENCE ]; then
    CC_SEQUENCE=$((COMMITTED_CC_SEQUENCE+1))
  else
    CC_SEQUENCE=$APPROVED_CC_SEQUENCE
  fi
}

queryInstalledOnPeer() {
  local rc=1
  local COUNTER=1
  # continue to poll
  # we either get a successful response, or reach MAX RETRY
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    #sleep $DELAY
    #infoln "Attempting to list on peer0.org${ORG}, Retry after $DELAY seconds."
    peer lifecycle chaincode queryinstalled >&log.txt
    res=$?
    let rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
}

queryCommittedOnChannel() {
  CHANNEL=mychannel
  local rc=1
  local COUNTER=1
  # continue to poll
  # we either get a successful response, or reach MAX RETRY
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    #sleep $DELAY
    #infoln "Attempting to list on peer0.org${ORG}, Retry after $DELAY seconds."
    peer lifecycle chaincode querycommitted -C $CHANNEL >&log.txt
    res=$?
    let rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  if test $rc -ne 0; then
    fatalln "After $MAX_RETRY attempts, Failed to retrieve committed chaincode!"
  fi
}

## Function to list chaincodes installed on the peer and committed chaincode visible to the org
listAllCommitted() {
  local rc=1
  local COUNTER=1
  # continue to poll
  # we either get a successful response, or reach MAX RETRY
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    CHANNEL_LIST=$(peer channel list | sed '1,1d')
    res=$?
    let rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done
  if test $rc -eq 0; then
    for channel in $CHANNEL_LIST
    do
      queryCommittedOnChannel "$channel"
    done
  else
    fatalln "After $MAX_RETRY attempts, Failed to retrieve committed chaincode!"
  fi
}

chaincodeInvoke() {
  ORG=$1
  CHANNEL=$2
  CC_NAME=$3
  CC_INVOKE_CONSTRUCTOR=$4
  
  infoln "Invoking on peer0.org${ORG} on channel '$CHANNEL_NAME'..."
  local rc=1
  local COUNTER=1
  # continue to poll
  # we either get a successful response, or reach MAX RETRY
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    infoln "Attempting to Invoke on peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer chaincode invoke -o localhost:7050 -C $CHANNEL_NAME -n ${CC_NAME} -c ${CC_INVOKE_CONSTRUCTOR} --tls --cafile "./organizations/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem"  --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_ORG1_CA --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_ORG2_CA  >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    let rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  if test $rc -eq 0; then
    successln "Invoke successful on peer0.org${ORG} on channel '$CHANNEL_NAME'"
  else
    fatalln "After $MAX_RETRY attempts, Invoke result on peer0.org${ORG} is INVALID!"
  fi
}

chaincodeQuery() {
  ORG=$1
  CHANNEL=$2
  CC_NAME=$3
  CC_QUERY_CONSTRUCTOR=$4

  infoln "Querying on peer0.org${ORG} on channel '$CHANNEL_NAME'..."
  local rc=1
  local COUNTER=1
  # continue to poll
  # we either get a successful response, or reach MAX RETRY
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    infoln "Attempting to Query peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c ${CC_QUERY_CONSTRUCTOR} >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    let rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  if test $rc -eq 0; then
    successln "Query successful on peer0.org${ORG} on channel '$CHANNEL_NAME'"
  else
    fatalln "After $MAX_RETRY attempts, Query result on peer0.org${ORG} is INVALID!"
  fi
}