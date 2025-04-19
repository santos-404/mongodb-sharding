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
chown -R mongodb:mongodb /data/configdb
chown -R mongodb:mongodb /var/log/mongodb
chmod 700 /opt/mongodb

# Updated to use the same keyfile on every machine 
cp /vagrant/shared/mongodb-keyfile /opt/mongodb/keyfile
chown -R mongodb:mongodb /opt/mongodb
chmod 400 /opt/mongodb/keyfile


cat > /etc/mongod.conf << EOF
storage:
  dbPath: /data/configdb 
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log
net:
  port: 27019
  bindIpAll: true
sharding:
  clusterRole: configsvr
replication:
  replSetName: configReplSet
EOF

# Start MongoDB with no authentication
systemctl daemon-reload
systemctl start mongod
systemctl status mongod

echo "Waiting for MongoDB to start..."
sleep 15  # We waitn for Mongo, just chill


echo "Initializing replica set..."
mongosh --port 27019 << EOF
rs.initiate(
  {
    _id: "configReplSet",
    configsvr: true,
    members: [
      { _id : 0, host : "192.168.56.10:27019" }
    ]
  }
)
EOF

echo "Waiting for replica set initialization..."
sleep 10  # Now waitn for the replica set, be patient!


# Now we add the admin; we just having fun, i think the pwd is ok 
echo "Creating admin user..."
mongosh --port 27019 << EOF
use admin
db.createUser(
  {
    user: "mongoAdmin",
    pwd: "hackable_pwd",
    roles: [ { role: "root", db: "admin" } ]
  }
)
EOF

# Now we need to enable authentication
cat > /etc/mongod.conf << EOF
storage:
  dbPath: /data/configdb 
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log
net:
  port: 27019
  bindIpAll: true
sharding:
  clusterRole: configsvr
replication:
  replSetName: configReplSet
security:
  keyFile: /opt/mongodb/keyfile
  authorization: enabled
EOF

systemctl restart mongod

echo "Verifying MongoDB is running..."
systemctl status mongod  # This is just a checker :D

echo "MongoDB Config Server setup completed"
echo "You can connect using: mongosh --port 27019 -u mongoAdmin -p hackable_pwd --authenticationDatabase admin"
