#!/bin/bash

source scriptUtils.sh
export PATH=${PWD}/./bin:$PATH


function createOrgCertificate() {
  infoln "Enrolling the CA admin"
  mkdir -p ./organizations/crypto-config/peerOrganizations/dyno/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/crypto-config/peerOrganizations/dyno/


  fabric-ca-client enroll -u https://admin:adminpw@localhost:4400 --caname ca-dyno --tls.certfiles ${PWD}/organizations/fabric-ca/dyno/tls-cert.pem


  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-4400-ca-dyno.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-4400-ca-dyno.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-4400-ca-dyno.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-4400-ca-dyno.pem
    OrganizationalUnitIdentifier: orderer' >${PWD}/organizations/crypto-config/peerOrganizations/dyno/msp/config.yaml


  # Registering peer0
  fabric-ca-client register --caname ca-dyno --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/organizations/fabric-ca/dyno/tls-cert.pem


  # Registering peer1
  fabric-ca-client register --caname ca-dyno --id.name peer1 --id.secret peer1pw --id.type peer --tls.certfiles ${PWD}/organizations/fabric-ca/dyno/tls-cert.pem

  # Registering peer2
  fabric-ca-client register --caname ca-dyno --id.name peer2 --id.secret peer2pw --id.type peer --tls.certfiles ${PWD}/organizations/fabric-ca/dyno/tls-cert.pem

  # Registering user
  fabric-ca-client register --caname ca-dyno --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/organizations/fabric-ca/dyno/tls-cert.pem


  # Registering the org admin
  fabric-ca-client register --caname ca-dyno --id.name dynoAdmin --id.secret dynoAdminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/dyno/tls-cert.pem


  # Generating the peer0 msp
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:4400 --caname ca-dyno -M ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer0.dyno/msp --csr.hosts peer0.dyno --tls.certfiles ${PWD}/organizations/fabric-ca/dyno/tls-cert.pem

  # "Generating the peer1 msp"
  fabric-ca-client enroll -u https://peer1:peer1pw@localhost:4400 --caname ca-dyno -M ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer1.dyno/msp --csr.hosts peer1.dyno --tls.certfiles ${PWD}/organizations/fabric-ca/dyno/tls-cert.pem

  # "Generating the peer2 msp"
  fabric-ca-client enroll -u https://peer2:peer2pw@localhost:4400 --caname ca-dyno -M ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer2.dyno/msp --csr.hosts peer2.dyno --tls.certfiles ${PWD}/organizations/fabric-ca/dyno/tls-cert.pem

  cp ${PWD}/organizations/crypto-config/peerOrganizations/dyno/msp/config.yaml ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer0.dyno/msp/config.yaml
  cp ${PWD}/organizations/crypto-config/peerOrganizations/dyno/msp/config.yaml ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer1.dyno/msp/config.yaml
  cp ${PWD}/organizations/crypto-config/peerOrganizations/dyno/msp/config.yaml ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer2.dyno/msp/config.yaml

  # Generating the peer0-tls certificates
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:4400 --caname ca-dyno -M ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer0.dyno/tls --enrollment.profile tls --csr.hosts peer0.dyno --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/dyno/tls-cert.pem

  # Generating the peer1-tls certificates
  fabric-ca-client enroll -u https://peer1:peer1pw@localhost:4400 --caname ca-dyno -M ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer1.dyno/tls --enrollment.profile tls --csr.hosts peer1.dyno --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/dyno/tls-cert.pem

  # Generating the peer2-tls certificates
  fabric-ca-client enroll -u https://peer2:peer2pw@localhost:4400 --caname ca-dyno -M ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer2.dyno/tls --enrollment.profile tls --csr.hosts peer2.dyno --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/dyno/tls-cert.pem

  # copy cerificate ca.crt, server.crt, server.key
  cp ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer0.dyno/tls/tlscacerts/* ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer0.dyno/tls/ca.crt
  cp ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer0.dyno/tls/signcerts/* ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer0.dyno/tls/server.crt
  cp ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer0.dyno/tls/keystore/* ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer0.dyno/tls/server.key

  cp ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer1.dyno/tls/tlscacerts/* ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer1.dyno/tls/ca.crt
  cp ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer1.dyno/tls/signcerts/* ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer1.dyno/tls/server.crt
  cp ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer1.dyno/tls/keystore/* ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer1.dyno/tls/server.key

  cp ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer2.dyno/tls/tlscacerts/* ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer2.dyno/tls/ca.crt
  cp ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer2.dyno/tls/signcerts/* ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer2.dyno/tls/server.crt
  cp ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer2.dyno/tls/keystore/* ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer2.dyno/tls/server.key

  # copy certificate from tlscarts => ca.crt , tlsca.dyno-cert.pem, ca.dyno-cert.pem
  mkdir -p ${PWD}/organizations/crypto-config/peerOrganizations/dyno/msp/tlscacerts
  cp ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer0.dyno/tls/tlscacerts/* ${PWD}/organizations/crypto-config/peerOrganizations/dyno/msp/tlscacerts/ca.crt

  mkdir -p ${PWD}/organizations/crypto-config/peerOrganizations/dyno/tlsca
  cp ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer0.dyno/tls/tlscacerts/* ${PWD}/organizations/crypto-config/peerOrganizations/dyno/tlsca/tlsca.dyno-cert.pem

  mkdir -p ${PWD}/organizations/crypto-config/peerOrganizations/dyno/ca
  cp ${PWD}/organizations/crypto-config/peerOrganizations/dyno/peers/peer0.dyno/msp/cacerts/* ${PWD}/organizations/crypto-config/peerOrganizations/dyno/ca/ca.dyno-cert.pem

  # Generating the user msp
  fabric-ca-client enroll -u https://user:userpw@localhost:4400 --caname ca-dyno -M ${PWD}/organizations/crypto-config/peerOrganizations/dyno/users/User@dyno/msp --tls.certfiles ${PWD}/organizations/fabric-ca/dyno/tls-cert.pem


  cp ${PWD}/organizations/crypto-config/peerOrganizations/dyno/msp/config.yaml ${PWD}/organizations/crypto-config/peerOrganizations/dyno/users/User@dyno/msp/config.yaml

  # Generating the org admin msp
  fabric-ca-client enroll -u https://dynoAdmin:dynoAdminpw@localhost:4400 --caname ca-dyno -M ${PWD}/organizations/crypto-config/peerOrganizations/dyno/users/Admin@dyno/msp --tls.certfiles ${PWD}/organizations/fabric-ca/dyno/tls-cert.pem


  cp ${PWD}/organizations/crypto-config/peerOrganizations/dyno/msp/config.yaml ${PWD}/organizations/crypto-config/peerOrganizations/dyno/users/Admin@dyno/msp/config.yaml
}


function createorderer() {
  # "Enrolling the CA admin"
  mkdir -p ./organizations/crypto-config/ordererOrganizations/orderer

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/crypto-config/ordererOrganizations/orderer


  fabric-ca-client enroll -u https://admin:adminpw@localhost:2200 --caname ca-orderer --tls.certfiles ${PWD}/organizations/fabric-ca/orderer/tls-cert.pem


  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-2200-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-2200-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-2200-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-2200-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer' >${PWD}/organizations/crypto-config/ordererOrganizations/orderer/msp/config.yaml

  # Registering orderer
  fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/organizations/fabric-ca/orderer/tls-cert.pem


  # Registering the orderer admin"
  fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/orderer/tls-cert.pem


  # Generating the orderer msp
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:2200 --caname ca-orderer -M ${PWD}/organizations/crypto-config/ordererOrganizations/orderer/config.orderers/msp --csr.hosts orderer --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/orderer/tls-cert.pem


  cp ${PWD}/organizations/crypto-config/ordererOrganizations/orderer/msp/config.yaml ${PWD}/organizations/crypto-config/ordererOrganizations/orderer/config.orderers/msp/config.yaml

  # Generating the orderer-tls certificates
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:2200 --caname ca-orderer -M ${PWD}/organizations/crypto-config/ordererOrganizations/orderer/config.orderers/tls --enrollment.profile tls --csr.hosts orderer --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/orderer/tls-cert.pem


  cp ${PWD}/organizations/crypto-config/ordererOrganizations/orderer/config.orderers/tls/tlscacerts/* ${PWD}/organizations/crypto-config/ordererOrganizations/orderer/config.orderers/tls/ca.crt
  cp ${PWD}/organizations/crypto-config/ordererOrganizations/orderer/config.orderers/tls/signcerts/* ${PWD}/organizations/crypto-config/ordererOrganizations/orderer/config.orderers/tls/server.crt
  cp ${PWD}/organizations/crypto-config/ordererOrganizations/orderer/config.orderers/tls/keystore/* ${PWD}/organizations/crypto-config/ordererOrganizations/orderer/config.orderers/tls/server.key

  mkdir -p ${PWD}/organizations/crypto-config/ordererOrganizations/orderer/config.orderers/msp/tlscacerts
  cp ${PWD}/organizations/crypto-config/ordererOrganizations/orderer/config.orderers/tls/tlscacerts/* ${PWD}/organizations/crypto-config/ordererOrganizations/orderer/config.orderers/msp/tlscacerts/tlsca-cert.pem

  mkdir -p ${PWD}/organizations/crypto-config/ordererOrganizations/orderer/msp/tlscacerts
  cp ${PWD}/organizations/crypto-config/ordererOrganizations/orderer/config.orderers/tls/tlscacerts/* ${PWD}/organizations/crypto-config/ordererOrganizations/orderer/msp/tlscacerts/tlsca-cert.pem

  # Generating the admin msp
  fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:2200 --caname ca-orderer -M ${PWD}/organizations/crypto-config/ordererOrganizations/orderer/users/Admin@example.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/orderer/tls-cert.pem


  cp ${PWD}/organizations/crypto-config/ordererOrganizations/orderer/msp/config.yaml ${PWD}/organizations/crypto-config/ordererOrganizations/orderer/users/Admin@example.com/msp/config.yaml
}

createOrgCertificate

createorderer



