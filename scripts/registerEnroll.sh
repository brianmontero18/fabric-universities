#!/bin/bash

function createIEBS() {
  echo "Enrolling the CA admin"
  mkdir -p organizations/peerOrganizations/iebs.universidades.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/iebs.universidades.com/

  fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca-iebs --tls.certfiles ${PWD}/organizations/fabric-ca/iebs/ca-cert.pem

  echo "Registering peer0"
  fabric-ca-client register --caname ca-iebs --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/organizations/fabric-ca/iebs/ca-cert.pem

  echo "Registering user1"
  fabric-ca-client register --caname ca-iebs --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/organizations/fabric-ca/iebs/ca-cert.pem

  echo "Registering admin"
  fabric-ca-client register --caname ca-iebs --id.name iebsadmin --id.secret iebsadminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/iebs/ca-cert.pem

  mkdir -p organizations/peerOrganizations/iebs.universidades.com/peers
  mkdir -p organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com
  mkdir -p organizations/peerOrganizations/iebs.universidades.com/users/Admin@iebs.universidades.com

  echo "Generating the peer0 msp"
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-iebs -M ${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/msp --csr.hosts peer0.iebs.universidades.com --tls.certfiles ${PWD}/organizations/fabric-ca/iebs/ca-cert.pem

  echo "Generating the peer0-tls certificates"
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-iebs -M ${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls --enrollment.profile tls --csr.hosts peer0.iebs.universidades.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/iebs/ca-cert.pem

  echo "Generating the admin msp"
  fabric-ca-client enroll -u https://iebsadmin:iebsadminpw@localhost:7054 --caname ca-iebs -M ${PWD}/organizations/peerOrganizations/iebs.universidades.com/users/Admin@iebs.universidades.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/iebs/ca-cert.pem

  # Copy the admin cert into the peer MSP directory
  mkdir -p ${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/msp/admincerts
  cp ${PWD}/organizations/peerOrganizations/iebs.universidades.com/users/Admin@iebs.universidades.com/msp/signcerts/* ${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/msp/admincerts/Admin@iebs.universidades.com-cert.pem

  # Setup peer0 TLS
  cp ${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/ca.crt
  cp ${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/signcerts/* ${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/server.crt
  cp ${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/keystore/* ${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/server.key

  mkdir -p ${PWD}/organizations/peerOrganizations/iebs.universidades.com/msp/tlscacerts
  cp ${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/iebs.universidades.com/msp/tlscacerts/ca.crt

  mkdir -p ${PWD}/organizations/peerOrganizations/iebs.universidades.com/tlsca
  cp ${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/iebs.universidades.com/tlsca/tlsca.iebs.universidades.com-cert.pem

  mkdir -p ${PWD}/organizations/peerOrganizations/iebs.universidades.com/ca
  cp ${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/msp/cacerts/* ${PWD}/organizations/peerOrganizations/iebs.universidades.com/ca/ca.iebs.universidades.com-cert.pem

  # Setup MSP config
  mkdir -p ${PWD}/organizations/peerOrganizations/iebs.universidades.com/msp
  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-iebs.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-iebs.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-iebs.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-iebs.pem
    OrganizationalUnitIdentifier: orderer' > ${PWD}/organizations/peerOrganizations/iebs.universidades.com/msp/config.yaml

  # Copy config to peer and admin MSP
  cp ${PWD}/organizations/peerOrganizations/iebs.universidades.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/msp/config.yaml
  cp ${PWD}/organizations/peerOrganizations/iebs.universidades.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/iebs.universidades.com/users/Admin@iebs.universidades.com/msp/config.yaml

  # Copy certificates to appropriate locations
  mkdir -p ${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/msp/cacerts
  cp ${PWD}/organizations/peerOrganizations/iebs.universidades.com/ca/ca.iebs.universidades.com-cert.pem ${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/msp/cacerts/

  mkdir -p ${PWD}/organizations/peerOrganizations/iebs.universidades.com/users/Admin@iebs.universidades.com/msp/cacerts
  cp ${PWD}/organizations/peerOrganizations/iebs.universidades.com/ca/ca.iebs.universidades.com-cert.pem ${PWD}/organizations/peerOrganizations/iebs.universidades.com/users/Admin@iebs.universidades.com/msp/cacerts/

  mkdir -p ${PWD}/organizations/peerOrganizations/iebs.universidades.com/users/Admin@iebs.universidades.com/msp/tlscacerts
  cp ${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/iebs.universidades.com/users/Admin@iebs.universidades.com/msp/tlscacerts/tlsca.iebs.universidades.com-cert.pem
}

function createTEC() {
  echo "Enrolling the CA admin"
  mkdir -p organizations/peerOrganizations/tec.universidades.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/tec.universidades.com/

  fabric-ca-client enroll -u https://admin:adminpw@localhost:8054 --caname ca-tec --tls.certfiles ${PWD}/organizations/fabric-ca/tec/ca-cert.pem

  echo "Registering peer0"
  fabric-ca-client register --caname ca-tec --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/organizations/fabric-ca/tec/ca-cert.pem

  echo "Registering user1"
  fabric-ca-client register --caname ca-tec --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/organizations/fabric-ca/tec/ca-cert.pem

  echo "Registering admin"
  fabric-ca-client register --caname ca-tec --id.name tecadmin --id.secret tecadminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/tec/ca-cert.pem

  mkdir -p organizations/peerOrganizations/tec.universidades.com/peers
  mkdir -p organizations/peerOrganizations/tec.universidades.com/peers/peer0.tec.universidades.com
  mkdir -p organizations/peerOrganizations/tec.universidades.com/users/Admin@tec.universidades.com

  echo "Generating the peer0 msp"
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-tec -M ${PWD}/organizations/peerOrganizations/tec.universidades.com/peers/peer0.tec.universidades.com/msp --csr.hosts peer0.tec.universidades.com --tls.certfiles ${PWD}/organizations/fabric-ca/tec/ca-cert.pem

  echo "Generating the peer0-tls certificates"
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-tec -M ${PWD}/organizations/peerOrganizations/tec.universidades.com/peers/peer0.tec.universidades.com/tls --enrollment.profile tls --csr.hosts peer0.tec.universidades.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/tec/ca-cert.pem

  echo "Generating the admin msp"
  fabric-ca-client enroll -u https://tecadmin:tecadminpw@localhost:8054 --caname ca-tec -M ${PWD}/organizations/peerOrganizations/tec.universidades.com/users/Admin@tec.universidades.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/tec/ca-cert.pem

  # Copy the admin cert into the peer MSP directory
  mkdir -p ${PWD}/organizations/peerOrganizations/tec.universidades.com/peers/peer0.tec.universidades.com/msp/admincerts
  cp ${PWD}/organizations/peerOrganizations/tec.universidades.com/users/Admin@tec.universidades.com/msp/signcerts/* ${PWD}/organizations/peerOrganizations/tec.universidades.com/peers/peer0.tec.universidades.com/msp/admincerts/Admin@tec.universidades.com-cert.pem

  # Setup peer0 TLS
  cp ${PWD}/organizations/peerOrganizations/tec.universidades.com/peers/peer0.tec.universidades.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/tec.universidades.com/peers/peer0.tec.universidades.com/tls/ca.crt
  cp ${PWD}/organizations/peerOrganizations/tec.universidades.com/peers/peer0.tec.universidades.com/tls/signcerts/* ${PWD}/organizations/peerOrganizations/tec.universidades.com/peers/peer0.tec.universidades.com/tls/server.crt
  cp ${PWD}/organizations/peerOrganizations/tec.universidades.com/peers/peer0.tec.universidades.com/tls/keystore/* ${PWD}/organizations/peerOrganizations/tec.universidades.com/peers/peer0.tec.universidades.com/tls/server.key

  mkdir -p ${PWD}/organizations/peerOrganizations/tec.universidades.com/msp/tlscacerts
  cp ${PWD}/organizations/peerOrganizations/tec.universidades.com/peers/peer0.tec.universidades.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/tec.universidades.com/msp/tlscacerts/ca.crt

  mkdir -p ${PWD}/organizations/peerOrganizations/tec.universidades.com/tlsca
  cp ${PWD}/organizations/peerOrganizations/tec.universidades.com/peers/peer0.tec.universidades.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/tec.universidades.com/tlsca/tlsca.tec.universidades.com-cert.pem

  mkdir -p ${PWD}/organizations/peerOrganizations/tec.universidades.com/ca
  cp ${PWD}/organizations/peerOrganizations/tec.universidades.com/peers/peer0.tec.universidades.com/msp/cacerts/* ${PWD}/organizations/peerOrganizations/tec.universidades.com/ca/ca.tec.universidades.com-cert.pem

  # Setup MSP config
  mkdir -p ${PWD}/organizations/peerOrganizations/tec.universidades.com/msp
  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-tec.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-tec.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-tec.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-tec.pem
    OrganizationalUnitIdentifier: orderer' > ${PWD}/organizations/peerOrganizations/tec.universidades.com/msp/config.yaml

  # Copy config to peer and admin MSP
  cp ${PWD}/organizations/peerOrganizations/tec.universidades.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/tec.universidades.com/peers/peer0.tec.universidades.com/msp/config.yaml
  cp ${PWD}/organizations/peerOrganizations/tec.universidades.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/tec.universidades.com/users/Admin@tec.universidades.com/msp/config.yaml

  # Copy certificates to appropriate locations
  mkdir -p ${PWD}/organizations/peerOrganizations/tec.universidades.com/peers/peer0.tec.universidades.com/msp/cacerts
  cp ${PWD}/organizations/peerOrganizations/tec.universidades.com/ca/ca.tec.universidades.com-cert.pem ${PWD}/organizations/peerOrganizations/tec.universidades.com/peers/peer0.tec.universidades.com/msp/cacerts/

  mkdir -p ${PWD}/organizations/peerOrganizations/tec.universidades.com/users/Admin@tec.universidades.com/msp/cacerts
  cp ${PWD}/organizations/peerOrganizations/tec.universidades.com/ca/ca.tec.universidades.com-cert.pem ${PWD}/organizations/peerOrganizations/tec.universidades.com/users/Admin@tec.universidades.com/msp/cacerts/

  mkdir -p ${PWD}/organizations/peerOrganizations/tec.universidades.com/users/Admin@tec.universidades.com/msp/tlscacerts
  cp ${PWD}/organizations/peerOrganizations/tec.universidades.com/peers/peer0.tec.universidades.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/tec.universidades.com/users/Admin@tec.universidades.com/msp/tlscacerts/tlsca.tec.universidades.com-cert.pem
}

function createOrderer() {
  echo "Enrolling the CA admin"
  mkdir -p organizations/ordererOrganizations/universidades.com

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/universidades.com

  fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 --caname ca-orderer --tls.certfiles ${PWD}/organizations/fabric-ca/orderer/ca-cert.pem

  echo "Registering orderer"
  fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/organizations/fabric-ca/orderer/ca-cert.pem

  echo "Registering admin"
  fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/orderer/ca-cert.pem

  mkdir -p organizations/ordererOrganizations/universidades.com/orderers
  mkdir -p organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com
  mkdir -p organizations/ordererOrganizations/universidades.com/users/Admin@universidades.com

  echo "Generating the orderer msp"
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp --csr.hosts orderer.universidades.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/orderer/ca-cert.pem

  echo "Generating the orderer-tls certificates"
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls --enrollment.profile tls --csr.hosts orderer.universidades.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/orderer/ca-cert.pem

  echo "Generating the admin msp"
  fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:9054 --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/universidades.com/users/Admin@universidades.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/orderer/ca-cert.pem

  # Copy the admin cert into the orderer MSP directory
  mkdir -p ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/admincerts
  cp ${PWD}/organizations/ordererOrganizations/universidades.com/users/Admin@universidades.com/msp/signcerts/* ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/admincerts/Admin@universidades.com-cert.pem

  # Setup orderer TLS
  cp ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/ca.crt
  cp ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/signcerts/* ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/server.crt
  cp ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/keystore/* ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/server.key

  mkdir -p ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts
  cp ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem

  mkdir -p ${PWD}/organizations/ordererOrganizations/universidades.com/msp/tlscacerts
  cp ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem

  mkdir -p ${PWD}/organizations/ordererOrganizations/universidades.com/ca
  cp ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/cacerts/* ${PWD}/organizations/ordererOrganizations/universidades.com/ca/ca.orderer.universidades.com-cert.pem

  # Setup MSP config
  mkdir -p ${PWD}/organizations/ordererOrganizations/universidades.com/msp
  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer' > ${PWD}/organizations/ordererOrganizations/universidades.com/msp/config.yaml

  # Copy config to orderer and admin MSP
  cp ${PWD}/organizations/ordererOrganizations/universidades.com/msp/config.yaml ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/config.yaml
  cp ${PWD}/organizations/ordererOrganizations/universidades.com/msp/config.yaml ${PWD}/organizations/ordererOrganizations/universidades.com/users/Admin@universidades.com/msp/config.yaml

  # Copy certificates to appropriate locations
  mkdir -p ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/cacerts
  cp ${PWD}/organizations/ordererOrganizations/universidades.com/ca/ca.orderer.universidades.com-cert.pem ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/cacerts/

  mkdir -p ${PWD}/organizations/ordererOrganizations/universidades.com/users/Admin@universidades.com/msp/cacerts
  cp ${PWD}/organizations/ordererOrganizations/universidades.com/ca/ca.orderer.universidades.com-cert.pem ${PWD}/organizations/ordererOrganizations/universidades.com/users/Admin@universidades.com/msp/cacerts/

  mkdir -p ${PWD}/organizations/ordererOrganizations/universidades.com/users/Admin@universidades.com/msp/tlscacerts
  cp ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/universidades.com/users/Admin@universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem
}