#!/bin/bash

# Variables de entorno para las organizaciones

export CORE_PEER_TLS_ENABLED=true

# Establecer variables específicas de la organización
setGlobals() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  echo "Using organization ${USING_ORG}"
  
  if [ $USING_ORG = "IEBS" ]; then
    export CORE_PEER_LOCALMSPID="IEBSMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/iebs.universidades.com/users/Admin@iebs.universidades.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
  elif [ $USING_ORG = "TEC" ]; then
    export CORE_PEER_LOCALMSPID="TECMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/tec.universidades.com/peers/peer0.tec.universidades.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/tec.universidades.com/users/Admin@tec.universidades.com/msp
    export CORE_PEER_ADDRESS=localhost:9051
  else
    echo "ORG Unknown"
  fi

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}

# Establecer variables del orderer
setOrdererGlobals() {
  export ORDERER_CA=${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem
  export ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/server.crt
  export ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/server.key
}