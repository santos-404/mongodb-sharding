#!/bin/bash

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

cat > /etc/mongos.conf << EOF
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongos.log
net:
  port: 27017
  bindIpAll: true
sharding:
  configDB: configReplSet/192.168.56.10:27019
security:
  keyFile: /opt/mongodb/keyfile
EOF

cat > /etc/systemd/system/mongos.service << EOF
[Unit]
Description=MongoDB Shard Router
After=network.target

[Service]
User=mongodb
Group=mongodb
ExecStart=/usr/bin/mongos --config /etc/mongos.conf
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable mongos
systemctl start mongos

echo "Waiting for mongos to start..."
sleep 15

mongosh --port 27017 << EOF
use admin
db.auth("mongoAdmin", "hackable_pwd")

sh.addShard("shard1ReplSet/192.168.56.11:27018")
sh.addShard("shard2ReplSet/192.168.56.12:27018")

// Enable sharding for a test database
sh.enableSharding("testdb")

// Create a sharded collection with a shard key
use testdb
db.createCollection("testcollection")
sh.shardCollection("testdb.testcollection", { _id: "hashed" })

// Show status
sh.status()
EOF

echo "MongoDB Router setup completed"
echo "You can connect to the router using: mongosh --port 27017 -u mongoAdmin -p hackable_pwd --authenticationDatabase admin"