#!/bin/bash

NODE_TYPE=$1

apt-get update
apt-get install -y gnupg curl

curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
   gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg \
   --dearmor

echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
apt-get update

apt-get install -y mongodb-org mongodb-mongosh

if [ "$NODE_TYPE" = "configsvr" ]; then
    mkdir -p /data/configdb
    chown -R mongodb:mongodb /data/configdb
elif [ "$NODE_TYPE" = "shard" ]; then
    mkdir -p /data/db
    chown -R mongodb:mongodb /data/db
fi

systemctl disable mongod
systemctl stop mongod

echo "MongoDB installation completed for $NODE_TYPE"
