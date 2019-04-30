#!/bin/bash

# Clean the yum cache
rm -fr /var/cache/yum/*
/usr/bin/yum clean all

# Install Puppet Labs Official Repository for CentOS 7
/bin/rpm -Uvh https://yum.puppet.com/puppet5/puppet5-release-el-6.noarch.rpm

# Install Puppet Server Components and Support Packages
/usr/bin/yum -y install puppetserver

# configure Hiera
cat > /var/tmp/configure_hiera.pp << 'EOF'
class { 'hiera':
  hiera_version   => '5',
  hiera5_defaults => { "datadir" => "data", "data_hash" => "yaml_data"},
  hierarchy  => [
    {"name" => "Nodes" => "nodes/%{trusted_certname}.yaml"},
    {"name" => "Environments" => "environments/%{::environment}.yaml"},
    {"name" => "Common Defaults" => "common.yaml"},
  ],
}
EOF

# Then Configure Hiera
  /opt/puppetlabs/puppet/bin/puppet apply /var/tmp/configure_hiera.pp

# Start and Enable the Puppet Master
/bin/systemctl start puppetserver
/bin/systemctl enable puppetserver
/bin/systemctl start puppet
/bin/systemctl enable puppet

# Install Git
/usr/bin/yum -y install git

# Configure the Puppet Master
cat > /var/tmp/configure_puppet_master.pp << EOF
  #####                   #####
  ## Configure Puppet Master ##
  #####                   #####

ini_setting { 'Master Agent Server':
  section => 'agent',
  setting => 'server',
  value   => 'master.puppet.vm',
}

ini_setting { 'Master Agent CertName':
  section => 'agent',
  setting => 'certname',
  value   => 'master.puppet.vm',
}
EOF

# Install and Configure PuppetDB
/opt/puppetlabs/puppet/bin/puppet module install puppetlabs-puppetdb
/opt/puppetlabs/puppet/bin/puppet apply -e "include puppetdb" --http_connect_timeout=5m || true
/opt/puppetlabs/puppet/bin/puppet apply -e "include puppetdb::master::config" --h  ttp_connect_timeout=5m || true

# Bounce the network to trade out the Virtualbox IP
/bin/systemctl restart network

# Stop and disable iptables
  /bin/systemctl stop firewalld.service
  /bin/systemctl disable firewalld.service
  /bin/systemctl stop iptables.service
  /bin/systemctl disable iptables.service
  /bin/systemctl stop ip6tables.service
  /bin/systemctl disable ip6tables

# Do initial Puppet Run
/opt/puppetlabs/puppet/bin/puppet agent -t --server=master.puppet.vm

# Place the r10k configuration file
cat > /var/tmp/configure_r10k.pp << 'EOF'
class { 'r10k':
  version => '3.1.1',
  sources => {
    'puppet' => {
      'remote'  => 'https://github.com/cvquesty/dg_control-repo.git',
      'basedir' => "${::settings::codedir}/environments",
      'prefix'  => false,
    }
  },
  manage_modulepath => false,
}
EOF

# Place the directory environments config file
cat > /var/tmp/configure_directory_environments.pp << 'EOF'
#####                            #####
## Configure Directory Environments ##
#####                            #####

# Default for ini_setting resource:
Ini_setting {
  ensure => 'present',
  path   => "${::settings::confdir}/puppet.conf",
}

ini_setting { 'Configure Environmentpath':
  section => 'main',
  setting => 'environmentpath',
  value   => '$codedir/environments',
}

ini_setting { 'Configure Basemodulepath':
  section => 'main',
  setting => 'basemodulepath',
  value   => '$confdir/modules:/opt/puppetlabs/puppet/modules',
}

ini_setting { 'Master Agent Server':
  section => 'agent',
  setting => 'server',
  value   => 'master.puppet.vm',
}

ini_setting { 'Master Agent Certname':
  section => 'agent',
  setting => 'certname',
  value   => 'master.puppet.vm',
}
EOF

# Install Puppet-r10k to configure r10k and all Dependencies
/opt/puppetlabs/puppet/bin/puppet module install -f puppet-r10k
/opt/puppetlabs/puppet/bin/puppet module install -f puppet-make
/opt/puppetlabs/puppet/bin/puppet module install -f puppetlabs-concat
/opt/puppetlabs/puppet/bin/puppet module install -f puppetlabs-stdlib
/opt/puppetlabs/puppet/bin/puppet module install -f puppetlabs-ruby
/opt/puppetlabs/puppet/bin/puppet module install -f puppetlabs-gcc
/opt/puppetlabs/puppet/bin/puppet module install -f puppet-make
/opt/puppetlabs/puppet/bin/puppet module install -f puppetlabs-inifile
/opt/puppetlabs/puppet/bin/puppet module install -f puppetlabs-vcsrepo
/opt/puppetlabs/puppet/bin/puppet module install -f puppetlabs-pe_gem
/opt/puppetlabs/puppet/bin/puppet module install -f puppetlabs-git
/opt/puppetlabs/puppet/bin/puppet module install -f gentoo-portage

# Now Apply Subsystem Configuration
/opt/puppetlabs/puppet/bin/puppet apply /var/tmp/configure_r10k.pp
/opt/puppetlabs/puppet/bin/puppet apply /var/tmp/configure_directory_environments.pp

# Install and Configure autosign.conf for agents
cat > /etc/puppetlabs/puppet/autosign.conf << 'EOF'
*.puppet.vm
EOF

# Initial r10k Deploy
/usr/bin/r10k deploy environment -pv

# Do Initial Puppet Run
/opt/puppetlabs/puppet/bin/puppet agent -t
