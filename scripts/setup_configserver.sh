#!/bin/bash

# Create MongoDB configuration file
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

mkdir -p /data/configdb
chown -R mongodb:mongodb /data/configdb

# Kill everything about mongo | MONGO -> X_DEATH_X
systemctl stop mongod 2>/dev/null
killall mongod 2>/dev/null

mkdir -p /opt/mongodb
chmod 700 /opt/mongodb

# Generate a keyfile for authentication between members of the replica set
openssl rand -base64 756 > /opt/mongodb/keyfile
chown mongodb:mongodb /opt/mongodb/keyfile
chmod 600 /opt/mongodb/keyfile

chown -R mongodb:mongodb /data/configdb

mkdir -p /var/log/mongodb
chown -R mongodb:mongodb /var/log/mongodb

systemctl daemon-reload
systemctl restart mongod
systemctl status mongod

# Wait wait wait. Be patient :D
sleep 10

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

# Create admin user (only run this on primary)
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

echo "MongoDB Config Server setup completed"
