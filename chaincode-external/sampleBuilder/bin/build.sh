#!/bin/sh

#!/bin/bash

set -euo pipefail

OUTPUT=$3

#external chaincodes expect connection.json file in the chaincode package
if [ ! -f "../../connection.json" ]; then
    >&2 echo "../../connection.json not found"
    exit 1
fi

#simply copy the endpoint information to specified output location
cp ../../connection.json ../connection.json

if [ -d "../../metadata" ]; then
    cp -a ../../metadata ../metadata
fi

exit 0