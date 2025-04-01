# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  
  config.vm.box = "ubuntu/focal64"  
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 512
    vb.cpus = 1
  end


  # ----------Config Server----------
  config.vm.define "configsrv" do |configsrv|
    configsrv.vm.hostname = "configsrv"
    configsrv.vm.network "private_network", ip: "192.168.56.10"
    configsrv.vm.provision "shell", path: "scripts/install_mongodb.sh"
    configsrv.vm.provision "shell", path: "scripts/setup_configserver.sh"
  end

end
