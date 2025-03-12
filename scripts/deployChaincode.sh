#!/bin/bash

CHANNEL_NAME="universidadeschannel"
CC_NAME="universities"
CC_SRC_PATH="./chaincode/universities"
CC_VERSION="1.0"
CC_SEQUENCE="1"
CC_INIT_FCN="InitLedger"
CC_END_POLICY="OR('IEBSMSP.peer','TECMSP.peer')"
CC_COLL_CONFIG=""
DELAY="3"
MAX_RETRY="5"

# importar utils
. scripts/envVar.sh
. scripts/utils.sh

packageChaincode() {
    set -x
    peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang golang --label ${CC_NAME}_${CC_VERSION} >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    cat log.txt
    verifyResult $res "Chaincode packaging has failed"
    echo "Chaincode is packaged"
}

# installChaincode PEER ORG
installChaincode() {
    PEER=$1
    ORG=$2
    setGlobals $PEER $ORG
    set -x
    peer lifecycle chaincode install ${CC_NAME}.tar.gz >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    cat log.txt
    verifyResult $res "Chaincode installation on peer${PEER}.${ORG} has failed"
    echo "Chaincode is installed on peer${PEER}.${ORG}"
}

# queryInstalled PEER ORG
queryInstalled() {
    PEER=$1
    ORG=$2
    setGlobals $PEER $ORG
    set -x
    peer lifecycle chaincode queryinstalled >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    cat log.txt
    PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
    verifyResult $res "Query installed on peer${PEER}.${ORG} has failed"
    echo "Query installed successful on peer${PEER}.${ORG} on channel"
}

# approveForMyOrg VERSION PEER ORG
approveForMyOrg() {
    PEER=$1
    ORG=$2
    setGlobals $PEER $ORG
    set -x
    peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.universidades.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    cat log.txt
    verifyResult $res "Chaincode definition approved on peer${PEER}.${ORG} on channel '$CHANNEL_NAME' failed"
    echo "Chaincode definition approved on peer${PEER}.${ORG} on channel '$CHANNEL_NAME'"
}

# checkCommitReadiness VERSION PEER ORG
checkCommitReadiness() {
    PEER=$1
    ORG=$2
    setGlobals $PEER $ORG
    echo "Checking the commit readiness of the chaincode definition on peer${PEER}.${ORG} on channel '$CHANNEL_NAME'..."
    local rc=1
    local COUNTER=1
    # continue to poll
    # we either get a successful response, or reach MAX RETRY
    while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
        sleep $DELAY
        echo "Attempting to check the commit readiness of the chaincode definition on peer${PEER}.${ORG}, Retry after $DELAY seconds."
        set -x
        peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} --output json >&log.txt
        res=$?
        { set +x; } 2>/dev/null
        let rc=0
        if [ $res -ne 0 ]; then
            let rc=1
        fi
        COUNTER=$(expr $COUNTER + 1)
    done
    cat log.txt
    if [ $rc -ne 0 ]; then
        echo "After $MAX_RETRY attempts, Check commit readiness result on peer${PEER}.${ORG} is INVALID!"
        exit 1
    fi
}

# commitChaincodeDefinition VERSION PEER ORG (PEER ORG)...
commitChaincodeDefinition() {
    parsePeerConnectionParameters $@
    res=$?
    verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    set -x
    peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.universidades.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} $PEER_CONN_PARMS --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    cat log.txt
    verifyResult $res "Chaincode definition commit failed on peer${PEER}.${ORG} on channel '$CHANNEL_NAME' failed"
    echo "Chaincode definition committed on channel '$CHANNEL_NAME'"
}

# queryCommitted ORG
queryCommitted() {
    PEER=$1
    ORG=$2
    setGlobals $PEER $ORG
    EXPECTED_RESULT="Version: ${CC_VERSION}, Sequence: ${CC_SEQUENCE}, Endorsement Plugin: escc, Validation Plugin: vscc"
    echo "Querying chaincode definition on peer${PEER}.${ORG} on channel '$CHANNEL_NAME'..."
    local rc=1
    local COUNTER=1
    # continue to poll
    # we either get a successful response, or reach MAX RETRY
    while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
        sleep $DELAY
        echo "Attempting to Query committed status on peer${PEER}.${ORG}, Retry after $DELAY seconds."
        set -x
        peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME} >&log.txt
        res=$?
        { set +x; } 2>/dev/null
        test $res -eq 0 && VALUE=$(cat log.txt | grep -o '^Version: '$CC_VERSION', Sequence: [0-9]*, Endorsement Plugin: escc, Validation Plugin: vscc')
        test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
        COUNTER=$(expr $COUNTER + 1)
    done
    cat log.txt
    if test $rc -eq 0; then
        echo "Query successful on peer${PEER}.${ORG} on channel '$CHANNEL_NAME'"
    else
        echo "After $MAX_RETRY attempts, Query result on peer${PEER}.${ORG} is INVALID!"
        exit 1
    fi
}

chaincodeInvokeInit() {
    parsePeerConnectionParameters $@
    res=$?
    verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

    # while 'peer chaincode' command can get the orderer endpoint from the
    # peer (if join was successful), let's supply it directly as we know
    # it using the "-o" option
    set -x
    fcn_call='{"function":"'${CC_INIT_FCN}'","Args":[]}'
    echo "invoke fcn call:${fcn_call}"
    peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.universidades.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CC_NAME} $PEER_CONN_PARMS --isInit -c ${fcn_call} >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    cat log.txt
    verifyResult $res "Invoke execution on $PEERS failed "
    echo "Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME'"
}

## Package the chaincode
packageChaincode

## Install chaincode on peer0.iebs and peer0.tec
echo "Installing chaincode on peer0.iebs..."
installChaincode 0 iebs
echo "Installing chaincode on peer0.tec..."
installChaincode 0 tec

## Query whether the chaincode is installed
queryInstalled 0 iebs

## Approve the definition for iebs
approveForMyOrg 0 iebs

## Check whether the chaincode definition is ready to be committed
checkCommitReadiness 0 iebs "\"IEBSMSP\": true"
checkCommitReadiness 0 tec "\"TECMSP\": false"

## Now approve for tec
approveForMyOrg 0 tec

## Check whether the chaincode definition is ready to be committed
checkCommitReadiness 0 iebs "\"IEBSMSP\": true"
checkCommitReadiness 0 tec "\"TECMSP\": true"

## Commit the chaincode definition
commitChaincodeDefinition 0 iebs 0 tec

## Query on both orgs to see that the definition committed successfully
queryCommitted 0 iebs
queryCommitted 0 tec

## Invoke the chaincode
chaincodeInvokeInit 0 iebs 0 tec

exit 0 