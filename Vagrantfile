# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'fileutils'
FileUtils.mkdir_p('./shared')
unless File.exist?('./shared/mongodb-keyfile')
  `openssl rand -base64 756 > ./shared/mongodb-keyfile`
  File.chmod(0600, './shared/mongodb-keyfile')
end

Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/jammy64"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024  
    vb.cpus = 1
  end

  config.vm.synced_folder "./shared", "/vagrant/shared"


  # ----------config server----------
  config.vm.define "configsrv" do |configsrv|
    configsrv.vm.hostname = "configsrv"
    configsrv.vm.network "private_network", ip: "192.168.56.10"
    configsrv.vm.provision "shell", path: "scripts/install_mongodb.sh", args: "configsrv"
    configsrv.vm.provision "shell", path: "scripts/setup_configserver.sh"
  end


  # ----------shard servers----------
  config.vm.define "shard1" do |shard1|
    shard1.vm.hostname = "shard1"
    shard1.vm.network "private_network", ip: "192.168.56.11"
    shard1.vm.provision "shell", path: "scripts/install_mongodb.sh", args: "shard"
    shard1.vm.provision "shell", path: "scripts/setup_shard.sh", args: "shard1 1"
  end
  
  config.vm.define "shard2" do |shard2|
    shard2.vm.hostname = "shard2"
    shard2.vm.network "private_network", ip: "192.168.56.12"
    shard2.vm.provision "shell", path: "scripts/install_mongodb.sh", args: "shard"
    shard2.vm.provision "shell", path: "scripts/setup_shard.sh", args: "shard2 2"
  end

end
