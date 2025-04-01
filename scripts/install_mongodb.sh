#!/bin/bash

apt-get install gnupg curl

curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
   gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg \
   --dearmor

echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
apt-get update

# I install a specific release so I'm sure all the VMs work always on the same MongoDB version
apt-get install -y mongodb-org=8.0.6 mongodb-org-database=8.0.6 mongodb-org-server=8.0.6 mongodb-mongosh mongodb-org-shell=8.0.6 mongodb-org-mongos=8.0.6 mongodb-org-tools=8.0.6 mongodb-org-database-tools-extra=8.0.6

# We are gonna use a custom configuration so I stop the services
systemctl stop mongod
systemctl disable mongod

mkdir -p /var/log/mongodb
chown -R mongodb:mongodb /var/log/mongodb
