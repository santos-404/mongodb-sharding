#!/bin/bash
SHARD_NAME=$1
SHARD_ID=$2

# I increase the max_map_count recommended by the logs
echo "Setting vm.max_map_count..."
sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" >> /etc/sysctl.conf

# Kill every mongo thing | Mongo -> DEATH 
systemctl stop mongod 2>/dev/null
killall mongod 2>/dev/null

mkdir -p /data/configdb
mkdir -p /var/log/mongodb
mkdir -p /opt/mongodb
chown -R mongodb:mongodb /data/db
chown -R mongodb:mongodb /var/log/mongodb
chmod 700 /opt/mongodb

# Updated to use the same keyfile on every machine 
cp /vagrant/shared/mongodb-keyfile /opt/mongodb/keyfile
chown -R mongodb:mongodb /opt/mongodb
chmod 400 /opt/mongodb/keyfile


cat > /etc/mongod.conf << EOF
storage:
  dbPath: /data/db
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log
net:
  port: 27018
  bindIpAll: true
sharding:
  clusterRole: shardsvr
replication:
  replSetName: ${SHARD_NAME}ReplSet
EOF

# Start MongoDB with no authentication
systemctl daemon-reload
systemctl start mongod
echo "Waiting for MongoDB to start..."
sleep 15

mongosh --port 27018 << EOF
rs.initiate(
  {
    _id: "${SHARD_NAME}ReplSet",
    members: [
      { _id: 0, host: "192.168.56.1${SHARD_ID}:27018" }
    ]
  }
)
EOF

echo "Waiting for replica set initialization..."
sleep 10

# Create the admin user (use the same credentials as the config server)
mongosh --port 27018 << EOF
use admin
db.createUser(
  {
    user: "mongoAdmin",
    pwd: "hackable_pwd",
    roles: [ { role: "root", db: "admin" } ]
  }
)
EOF

# Update the configuration to enable authentication
cat > /etc/mongod.conf << EOF
storage:
  dbPath: /data/db
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log
net:
  port: 27018
  bindIpAll: true
sharding:
  clusterRole: shardsvr
replication:
  replSetName: ${SHARD_NAME}ReplSet
security:
  keyFile: /opt/mongodb/keyfile
  authorization: enabled
EOF

# Restart MongoDB with authentication enabled
systemctl restart mongod
echo "Verifying MongoDB is running..."
systemctl status mongod

echo "MongoDB Shard Server ${SHARD_NAME} setup completed"
echo "You can connect using: mongosh --port 27018 -u mongoAdmin -p hackable_pwd --authenticationDatabase admin"
