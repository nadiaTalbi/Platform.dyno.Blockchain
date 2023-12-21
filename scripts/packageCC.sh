#!/bin/bash

#!/bin/bash

. scripts/scriptUtils.sh

CC_NAME=${1}
CC_SRC_PATH=${2}
CC_VERSION=${4}
CC_PACKAGE_ONLY=${5:-false}

println "executing with the following"
println "- CC_NAME: ${C_GREEN}${CC_NAME}${C_RESET}"
println "- CC_SRC_PATH: ${C_GREEN}${CC_SRC_PATH}${C_RESET}"
println "- CC_SRC_LANGUAGE: ${C_GREEN}${CC_SRC_LANGUAGE}${C_RESET}"
println "- CC_VERSION: ${C_GREEN}${CC_VERSION}${C_RESET}"

FABRIC_CFG_PATH=$PWD/compose/docker/peercfg


CC_SRC_LANGUAGE=$(echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:])

# language of the chaincode is javascript
CC_RUNTIME_LANGUAGE=node

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}

packageChaincode() {
  set -x
  # if [ ${CC_PACKAGE_ONLY} = true ] ; then
  #   mkdir -p packagedChaincode
  #   peer lifecycle chaincode package packagedChaincode/${CC_NAME}_${CC_VERSION}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_${CC_VERSION} >&log.txt
  # else
  #   peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_${CC_VERSION} >&log.txt
  # fi
  peer lifecycle chaincode package basic.tar.gz --path ./chaincode-javascript --lang node  --label basic_1.0

  res=$?

  { set +x; } 2>/dev/null
  cat log.txt
  PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid basic.tar.gz)
  verifyResult $res "Chaincode packaging has failed"
  successln "Chaincode is packaged"
}

## package the chaincode
packageChaincode

exit 0