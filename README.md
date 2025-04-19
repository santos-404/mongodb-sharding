# MongoDB Sharded Cluster Setup with Vagrant

A Vagrant-based setup for a MongoDB sharded cluster, including config servers, shard servers, and a mongos router

## Prerequisites

- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- [Vagrant](https://www.vagrantup.com/downloads)
- At least 4GB of free RAM
- 10GB of free disk space

## Architecture

The setup creates the following virtual machines:

1. **Config Server (configsrv)**: Stores metadata and configuration settings for the cluster
   - IP: 192.168.56.10
   - Port: 27019
   - Replica Set: configReplSet

2. **Shard 1 (shard1)**: Stores a portion of the actual data in the sharded cluster
   - IP: 192.168.56.11
   - Port: 27018
   - Replica Set: shard1ReplSet

3. **Shard 2 (shard2)**: Stores a portion of the actual data in the sharded cluster
   - IP: 192.168.56.12
   - Port: 27018
   - Replica Set: shard2ReplSet


## Directory Structure

```
mongodb-sharding/
├── Vagrantfile                  # Vagrant configuration
├── scripts/
│   ├── install_mongodb.sh       # Script to install MongoDB
│   ├── setup_shard.sh           # Script to set up each shard server 
│   └── setup_configserver.sh    # Script to set up config server
├── shared/
│   ├── mongodb-keyfile          # Shared keyfile accross the servers 
└── README.md                    # This file
```

## Installation and Setup

1. Clone this repository:
   ```bash
   git clone https://github.com/santos-404/mongodb-sharding 
   cd mongodb-sharding
   ```

2. Start the virtual machines:
   ```bash
   vagrant up
   ```
   This will create and provision all three VMs, which may take several minutes.

## Accessing the MongoDB Cluster

### On each server 

```bash
# SSH into the config server
vagrant ssh <server> 

# Connect to MongoDB
mongosh --port 27019 -u mongoAdmin -p hackable_pwd --authenticationDatabase admin

# Check replica set status
rs.status()
```

### Check everything with one command 

1. First, verify that MongoDB is running on all your nodes:

```bash
vagrant ssh configsrv -c "sudo systemctl status mongod"

vagrant ssh shard1 -c "sudo systemctl status mongod"
vagrant ssh shard2 -c "sudo systemctl status mongod"
```

2. Connect to the servers and check their replica set status:

```bash
vagrant ssh configsrv -c "mongosh --port 27019 -u mongoAdmin -p hackable_pwd --authenticationDatabase admin --eval 'rs.status()'"

vagrant ssh shard1 -c "mongosh --port 27018 -u mongoAdmin -p hackable_pwd --authenticationDatabase admin --eval 'rs.status()'"
vagrant ssh shard2 -c "mongosh --port 27018 -u mongoAdmin -p hackable_pwd --authenticationDatabase admin --eval 'rs.status()'"
```


## Managing the Cluster

### Adding More Shards

To add more shards, update the Vagrantfile to include additional shard servers and provision them:

```ruby
# ----------shard server X----------
config.vm.define "shardX" do |shardX|
  shard2.vm.hostname = "shardX"
  shard2.vm.network "private_network", ip: "192.168.56.YZ"
  shard2.vm.provision "shell", path: "scripts/install_mongodb.sh", args: "shard"
  shard2.vm.provision "shell", path: "scripts/setup_shardserver.sh", args: "shardX 192.168.56.YZ"
end
```

Then, add the new shard to the cluster:

```bash
vagrant ssh mongos
mongosh --port 27017 -u mongoAdmin -p hackable_pwd --authenticationDatabase admin
sh.addShard("shard2RS/192.168.56.YZ:27018")
```

## Security Notes

This setup includes basic security with:
- Authentication between cluster members using a keyfile
- An admin user for accessing the cluster
- Local network isolation

>**Warning**: The default password ("hackable_pwd"), as you can guess, is not secure. For any environment beyond development, please change it to a strong password.

## License

[MIT License](LICENSE)

## Thanks!

Made by [Javier Santos](https://github.com/santos-404) and [Josué Rodríguez](https://github.com/JosueRodLop) 
