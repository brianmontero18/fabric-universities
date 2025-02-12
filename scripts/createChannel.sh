#!/bin/bash

# Importar utilidades comunes y variables de entorno
. scripts/envVar.sh

CHANNEL_NAME="universidadeschannel"
DELAY="3"
MAX_RETRY="5"
VERBOSE="false"

# Función para crear el canal
createChannel() {
    setGlobals "IEBS"
    setOrdererGlobals     # Agregar esta línea
    
    # Poll in case the orderer isn't ready yet
    local rc=1
    local COUNTER=1
    while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
        sleep $DELAY
        set -x
        peer channel create -o localhost:7050 -c $CHANNEL_NAME \
            --ordererTLSHostnameOverride orderer.universidades.com \
            -f ${PWD}/channel-artifacts/${CHANNEL_NAME}.tx \
            --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block \
            --tls --cafile "$ORDERER_CA" >&log.txt    # Agregamos comillas
        res=$?
        { set +x; } 2>/dev/null
        let rc=$res
        COUNTER=$(expr $COUNTER + 1)
    done
    cat log.txt
    verifyResult $res "Canal creado exitosamente"
    echo "===================== Canal '$CHANNEL_NAME' creado ===================== "
}

# Función para unir IEBS al canal
joinIEBS() {
	setGlobals "IEBS"
	local rc=1
	local COUNTER=1
	## A veces necesita intentar varias veces... haz 5 intentos
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block >&log.txt
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Peer IEBS unido al canal"
	echo "===================== Peer IEBS unido al canal '$CHANNEL_NAME' ===================== "
}

# Función para unir TEC al canal
joinTEC() {
	setGlobals "TEC"
	local rc=1
	local COUNTER=1
	## A veces necesita intentar varias veces... haz 5 intentos
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block >&log.txt
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Peer TEC unido al canal"
	echo "===================== Peer TEC unido al canal '$CHANNEL_NAME' ===================== "
}

# Función para actualizar el anchor peer de IEBS
updateAnchorPeersIEBS() {
	setGlobals "IEBS"
	local rc=1
	local COUNTER=1
	## A veces necesita intentar varias veces... haz 5 intentos
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.universidades.com -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $ORDERER_CA >&log.txt
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Anchor peers de IEBS actualizados exitosamente"
	echo "===================== Anchor peers de IEBS actualizados ===================== "
}

# Función para actualizar el anchor peer de TEC
updateAnchorPeersTEC() {
	setGlobals "TEC"
	local rc=1
	local COUNTER=1
	## A veces necesita intentar varias veces... haz 5 intentos
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.universidades.com -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $ORDERER_CA >&log.txt
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Anchor peers de TEC actualizados exitosamente"
	echo "===================== Anchor peers de TEC actualizados ===================== "
}

verifyResult() {
	if [ $1 -ne 0 ]; then
		echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
		echo
		exit 1
	fi
}

FABRIC_CFG_PATH=${PWD}/configtx

## Crear canal
echo "Creando canal..."
createChannel

## Unir las organizaciones al canal
echo "Uniendo IEBS al canal..."
joinIEBS
echo "Uniendo TEC al canal..."
joinTEC

## Establecer los anchor peers para cada org
echo "Actualizando anchor peers para IEBS..."
updateAnchorPeersIEBS
echo "Actualizando anchor peers para TEC..."
updateAnchorPeersTEC

echo
echo "===================== Canal configurado exitosamente ===================== "
echo

exit 0