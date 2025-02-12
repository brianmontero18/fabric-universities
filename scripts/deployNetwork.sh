#!/bin/bash

CHANNEL_NAME="universidadeschannel"

# Verificar que estamos en el directorio correcto
if [ ! -d "organizations" ] || [ ! -d "scripts" ] || [ ! -d "configtx" ]; then
    echo "Error: Este script debe ejecutarse desde el directorio raíz del proyecto"
    exit 1
fi

# Verificar binarios necesarios
for binary in configtxgen peer osnadmin fabric-ca-client; do
    if ! which $binary >/dev/null 2>&1; then
        echo "Error: $binary no encontrado. Asegúrate de que los binarios estén en el PATH"
        exit 1
    fi
done

# Detener contenedores previos y limpiar
function clearContainers() {
    docker stop $(docker ps -a -q)
    docker rm $(docker ps -a -q)
}

# Limpiar volúmenes y redes
function clearVolumes() {
    docker volume prune -f
    docker network prune -f
}

# Limpiar organizaciones previas
function clearOrganizations() {
    rm -rf organizations/peerOrganizations
    rm -rf organizations/ordererOrganizations
    rm -rf channel-artifacts/*
}

# Iniciar CAs
function startCA() {

    for port in 7054 8054 9054; do
        if netstat -tuln | grep ":$port " > /dev/null; then
            echo "Error: Puerto $port ya está en uso"
            exit 1
        fi
    done

    # Limpiar directorios CA previos
    rm -rf organizations/fabric-ca/*
    mkdir -p organizations/fabric-ca/iebs
    mkdir -p organizations/fabric-ca/tec
    mkdir -p organizations/fabric-ca/orderer

    echo "Iniciando servicios CA..."
    docker-compose -f docker/docker-compose-ca.yaml up -d

    # Esperar a que los CAs inicien y generen sus certificados
    for org in iebs tec orderer; do
        echo "Esperando a que el CA de $org esté listo..."
        while true; do
            if docker exec ca_$org ls /etc/hyperledger/fabric-ca-server/ca-cert.pem >/dev/null 2>&1; then
                mkdir -p organizations/fabric-ca/$org
                docker cp ca_$org:/etc/hyperledger/fabric-ca-server/ca-cert.pem organizations/fabric-ca/$org/
                docker cp ca_$org:/etc/hyperledger/fabric-ca-server/tls-cert.pem organizations/fabric-ca/$org/
                echo "CA de $org está listo"
                break
            fi
            echo "Esperando certificados de $org..."
            sleep 2
        done
    done

    echo "Todos los CAs están iniciados y certificados copiados"

    for org in iebs tec orderer; do
        echo "Verificando CA $org..."
        until docker logs ca_$org 2>&1 | grep -q "Listening on"; do
            sleep 1
            echo "Esperando CA $org..."
        done
    done
}

# Registrar identidades y generar certificados
function generateCertificates() {
    . scripts/registerEnroll.sh
    
    createIEBS
    createTEC
    createOrderer
}

# Crear el canal
function createChannel() {
    export FABRIC_CFG_PATH=${PWD}/configtx
    cp $PWD/config/core.yaml $FABRIC_CFG_PATH/
    
    mkdir -p channel-artifacts
    
    # Sistema de canal primero
    echo "Generando bloque génesis del sistema..."
    configtxgen -profile UniversidadesGenesis \
        -channelID system-channel \
        -outputBlock ./channel-artifacts/genesis.block
    
    if [ "$?" -ne 0 ]; then
        echo "Error generando bloque génesis del sistema"
        exit 1
    fi

    echo "Copiando bloque génesis..."
    cp channel-artifacts/genesis.block docker/channel-artifacts/

    # Transacción del canal de aplicación
    echo "Generando transacción del canal..."
    configtxgen -profile UniversidadesChannel \
        -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx \
        -channelID $CHANNEL_NAME

    if [ "$?" -ne 0 ]; then
        echo "Error generando transacción del canal"
        exit 1
    fi

    # Iniciar la red con el bloque génesis del sistema
    docker-compose -f docker/docker-compose-universidades.yaml up -d
    
    sleep 15
    
    # Llamar al script de creación de canal
    . scripts/createChannel.sh
}

# Unir peers al canal
function joinChannel() {
    # IEBS peer
    export CORE_PEER_TLS_ENABLED=true
    export PEER0_IEBS_CA=${PWD}/organizations/peerOrganizations/iebs.universidades.com/peers/peer0.iebs.universidades.com/tls/ca.crt
    export CORE_PEER_LOCALMSPID="IEBSMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_IEBS_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/iebs.universidades.com/users/Admin@iebs.universidades.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
    
    peer channel join -b ./channel-artifacts/universidadeschannel.block
    
    # TEC peer
    export PEER0_TEC_CA=${PWD}/organizations/peerOrganizations/tec.universidades.com/peers/peer0.tec.universidades.com/tls/ca.crt
    export CORE_PEER_LOCALMSPID="TECMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_TEC_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/tec.universidades.com/users/Admin@tec.universidades.com/msp
    export CORE_PEER_ADDRESS=localhost:9051
    
    peer channel join -b ./channel-artifacts/universidadeschannel.block
}

# Ejecutar el despliegue completo
clearContainers
clearVolumes
clearOrganizations
startCA
generateCertificates
createChannel
joinChannel

echo "Red desplegada exitosamente!"