#!/bin/bash

echo "Iniciando limpieza completa..."

# Detener todos los contenedores
echo "Deteniendo contenedores..."
docker stop $(docker ps -a -q) 2>/dev/null || true
docker rm $(docker ps -a -q) 2>/dev/null || true

# Eliminar volúmenes
echo "Eliminando volúmenes Docker..."
docker volume prune -f

# Eliminar redes
echo "Eliminando redes Docker..."
docker network prune -f

# Eliminar imágenes específicas de Fabric
echo "Eliminando imágenes de Hyperledger Fabric..."
docker rmi $(docker images "hyperledger/*" -q) 2>/dev/null || true

# Limpiar directorios
echo "Limpiando directorios del proyecto..."
sudo rm -rf organizations/fabric-ca/*
sudo rm -rf organizations/peerOrganizations
sudo rm -rf organizations/ordererOrganizations
sudo rm -rf channel-artifacts/*
sudo rm -rf *.tar.gz

echo "Limpiando directorios de docker..."
sudo rm -rf docker/channel-artifacts
sudo rm -rf docker/genesis.block
sudo rm -rf docker/universidadeschannel.block

# Crear directorios necesarios
echo "Recreando directorios..."
mkdir -p organizations/fabric-ca/iebs
mkdir -p organizations/fabric-ca/tec
mkdir -p organizations/fabric-ca/orderer
mkdir -p channel-artifacts

echo "Limpieza completada con éxito!"
echo "Para iniciar la red, ejecuta: ./scripts/deployNetwork.sh"