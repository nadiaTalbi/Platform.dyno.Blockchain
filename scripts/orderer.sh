#!/bin/bash

export PATH=${PWD}/./bin:$PATH

export ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/crypto-config/ordererOrganizations/orderer/config.orderers/tls/server.crt /dev/null 2>&1
export ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/crypto-config/ordererOrganizations/orderer/config.orderers/tls/server.key /dev/null 2>&1
export ORDERER_CA=${PWD}/organizations/crypto-config/ordererOrganizations/orderer/config.orderers/msp/tlscacerts/tlsca-cert.pem

# Create channel 
peer channel create -o localhost:7053 -c mychannel -f ./channel-artifacts/mychannel.tx --tls --cafile $ORDERER_CA
# To join orderer to a channel
osnadmin channel join --channelID mychannel --config-block ./channel-artifacts/mychannel.block -o localhost:7053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY" >> log.txt 2>&1