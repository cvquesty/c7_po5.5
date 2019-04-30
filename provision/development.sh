#!/bin/bash

# Turn off the Firewall and Disable it
/sbin/service iptables stop
/sbin/chkconfig iptables off
/sbin/service ip6tables stop
/sbin/chkconfig ip6tables off

# Install Puppet Labs Official Repository for CentOS 7
  /bin/rpm -Uvh https://yum.puppetlabs.com/puppet5/puppet5-release-el-6.noarch.rpm

# Install Puppet Server Components and Support Packages
/usr/bin/yum -y install puppet-agent
/sbin/service puppet start
/sbin/chkconfig puppet on

# Restart Networking to Pick Up New IP
/sbin/service network restart

# Create a puppet.conf
cat >> /etc/puppetlabs/puppet/puppet.conf << 'EOF'
certname = development.puppet.vm
server = master.puppet.vm
EOF

# Do initial Puppet Run
/opt/puppetlabs/puppet/bin/puppet agent -t
