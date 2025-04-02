# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|


  config.vm.box = "ubuntu/jammy64"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024  
    vb.cpus = 1
  end

  # ----------config server----------
  config.vm.define "configsrv" do |configsrv|
    configsrv.vm.hostname = "configsrv"
    configsrv.vm.network "private_network", ip: "192.168.56.10"
    configsrv.vm.provision "shell", path: "scripts/install_mongodb.sh", args: "configsvr"
    configsrv.vm.provision "shell", path: "scripts/setup_configserver.sh"
  end



end
