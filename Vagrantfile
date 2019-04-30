# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

######################
## Puppet Master VM ##
######################
  # Define the Master VM Characteristics
  config.vm.define 'master' do |master|
    master.vm.box = 'centos/7'
    master.vm.network :private_network, :ip => '10.10.100.100'
    master.vm.network "forwarded_port", guest: 443, host: 8443
    master.vm.hostname = 'master.puppet.vm'

  # Configure Master VM Settings
  master.vm.provider :virtualbox do |settings|
    settings.memory = 4608
    settings.name = "master_po5.5"
    settings.cpus = 2
  end

  # Add all other hosts for environment
  master.vm.provision :hosts do |entries|
    entries.add_host '10.10.100.100', ['master.puppet.vm', 'master']
    entries.add_host '10.10.100.111', ['development.puppet.vm', 'development']
    entries.add_host '10.10.100.112', ['production.puppet.vm', 'production']
  end

  # Run the custom provisioning
  master.vm.provision :shell, path: "provision/master.sh"
end

####################
## Development VM ##
####################
  # Define the Development VM Characteristics
  config.vm.define 'development' do |development|
    development.vm.box = 'centos/7'
    development.vm.network :private_network, :ip => '10.10.100.111'
    development.vm.hostname = 'development.puppet.vm'

  # Configure Development VM Settings
  development.vm.provider :virtualbox do |settings|
    settings.memory = 512
    settings.name = "development_po5.5"
    settings.cpus = 1
  end

  # Add all other hosts for environment
  development.vm.provision :hosts do |entries|
    entries.add_host '10.10.100.100', ['master.puppet.vm', 'master']
    entries.add_host '10.10.100.111', ['development.puppet.vm', 'development']
    entries.add_host '10.10.100.112', ['production.puppet.vm', 'production']
  end

  # Run the custom provisioning
  development.vm.provision :shell, path: "provision/development.sh"
end

###################
## Production VM ##
###################
  # Define the Production VM Characteristics
  config.vm.define 'production' do |production|
    production.vm.box = 'centos/7'
    production.vm.network :private_network, :ip => '10.10.100.112'
    production.vm.hostname = 'production.puppet.vm'

  # Configure Development VM Settings
  production.vm.provider :virtualbox do |settings|
    settings.memory = 512
    settings.name = "production_po5.5"
    settings.cpus = 1
  end

  # Add all other hosts for environment
  production.vm.provision :hosts do |entries|
    entries.add_host '10.10.100.100', ['master.puppet.vm', 'master']
    entries.add_host '10.10.100.111', ['development.puppet.vm', 'development']
    entries.add_host '10.10.100.112', ['production.puppet.vm', 'production']
  end

  # Run the custom provisioning
  production.vm.provision :shell, path: "provision/production.sh"
end
end
