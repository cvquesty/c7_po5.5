#!/bin/bash

# Stop and disable firewalld
  /bin/systemctl stop  firewalld.service
  /bin/systemctl disable firewalld.service

# Install Puppet Labs Official Repository for CentOS 7
  /bin/rpm -Uvh https://yum.puppetlabs.com/puppet5/puppet5-release-el-6.noarch.rpm

# Install Puppet Server Components and Support Packages
/usr/bin/yum -y install puppet-agent
/bin/systemctl start puppet
/bin/systemctl enable puppet

# Restart Networking to Pick Up New IP
/bin/systemctl restart network

# Create a puppet.conf
cat >> /etc/puppetlabs/puppet/puppet.conf << 'EOF'
certname = development.puppet.vm
server = master.puppet.vm
EOF

# Do initial Puppet Run
/opt/puppetlabs/puppet/bin/puppet agent -t
