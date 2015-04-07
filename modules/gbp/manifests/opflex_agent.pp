class gbp::opflex_agent(
  $opflex_log_level = 'debug5',
  $opflex_peer_ip = '10.0.0.30',
  $opflex_peer_port = '8009',
  $opflex_ssl_mode = 'enabled',
  $opflex_endpoint_dir = '/var/lib/opflex-agent-ovs/endpoints',
  $opflex_ovs_bridge_name = 'br-int',
  $opflex_encap_iface = 'br-int_vxlan0',
  $opflex_uplink_iface = 'eth1.4093',
  $opflex_uplink_vlan = '4093',
  $opflex_remote_ip = '10.0.0.32',
  $opflex_remote_port = '8472',
  $opflex_virtual_router = 'true',
  $opflex_router_advertisement = 'false',
  $opflex_virtual_router_mac = '00:22:bd:f8:19:ff',
  $opflex_virtual_dhcp_enabled = 'true',
  $opflex_virtual_dhcp_mac = '00:22:bd:f8:19:ff',
  $opflex_cache_dir = '/var/lib/opflex-agent-ovs/ids',
) {

   file {'/tmp/install_latest.sh':
     mode  => '0755',
     content => template('gbp/install_latest.sh.erb')
   }
   
   exec {'install-ovs':
     command  => '/tmp/install_latest.sh OVS',
     require  => File['/tmp/install_latest.sh'],
   }

   exec {'rmmod_openvswitch':
     command => "/usr/sbin/rmmod openvswitch",
     require => Exec['install-ovs'],
   }
 
   exec {'modprobe-openvswitch':
     command => "/usr/sbin/modprobe openvswitch",
     require => Exec['rmmod_openvswitch'],
     notify => Service['openvswitch'],
   }

   service {'openvswitch':
      ensure => running,
      enable => true,
   }
   
   exec {'get-libuv':
     command  => "/usr/bin/curl -o '/tmp/libuv-1.0.2-1.el7.x86_64.rpm' 'http://172.28.184.8/opflex/opflex_agent/libuv-1.0.2-1.el7.x86_64.rpm'",
   }
   
   exec {'get-libuvdev':
     command  => "/usr/bin/curl -o '/tmp/libuv-devel-1.0.2-1.el7.x86_64.rpm' 'http://172.28.184.8/opflex/opflex_agent/libuv-devel-1.0.2-1.el7.x86_64.rpm'",
   }
   
   exec {'install-libuv':
     command => "/usr/bin/rpm -Uhv --replacepkgs /tmp/libuv-1.0.2-1.el7.x86_64.rpm",
     require => Exec['get-libuv'],
   }
   
   exec {'install-libuv-dev':
     command => "/usr/bin/rpm -Uhv --replacepkgs /tmp/libuv-devel-1.0.2-1.el7.x86_64.rpm",
     require => Exec['get-libuvdev', 'install-libuv'],
   }
   
   exec {'install-opflex':
     command => '/tmp/install_latest.sh',
     require => [File['/tmp/install_latest.sh'], Exec['install-libuv'], Exec['install-libuv-dev'], Exec['modprobe-openvswitch']]
   }

   exec {'set_perm':
     command => "/usr/bin/chmod 777 $opflex_endpoint_dir",
     require => Exec['install-opflex'],
   }
   
   #dummy and YUCK to reduce dependency, will go away when we have proper repository based installation
   file {'/tmp/__install_complete':
     mode => '0777',
     content => 'crap',
     require => Exec['install-opflex', 'install-ovs', 'set_perm'],
   }
   
   ## Install defined, require the file /tmp/__install_complete for dependency
   
   file {'agent-conf':
     path => '/etc/opflex-agent-ovs/opflex-agent-ovs.conf',
     mode => '0644',
     content => template('gbp/opflex-agent-ovs.conf.erb'),
     require => File['/tmp/__install_complete'],
   }

   service {'agent-ovs':
     ensure => running,
     enable => true,
     require => File['agent-conf'],
   }

   exec {'replace_ovs_binary':
      command => "/usr/bin/sed -i -- 's/neutron-openvswitch-agent/openstack-opflex-agent/g' /usr/lib/systemd/system/neutron-openvswitch-agent.service; /usr/bin/systemctl daemon-reload",
      onlyif => "/bin/grep neutron-openvswitch-agent /usr/lib//systemd/system/neutron-openvswitch-agent.service | /usr/bin/wc -l",
      notify => Service['neutron-openvswitch-agent']
   }

   exec {'add_vxlan_port':
      command => "/usr/bin/ovs-vsctl add-port $opflex_ovs_bridge_name $opflex_encap_iface -- set Interface $opflex_encap_iface type=vxlan options:remote_ip=flow options:key=flow options:dst_port=8472",
      onlyif => "/usr/bin/ovs-vsctl show | /bin/grep $opflex_encap_iface | /usr/bin/wc -l",
      returns => [0,1,2],
   }

   service {'neutron-openvswitch-agent':
      ensure => running,
      enable => true,
   }

   exec {'offload':
      command => "/usr/sbin/ethtool --offload eth1.4093 tx off",
   }

   #exec {'del-old-br':
   #   command => "/usr/bin/ovs-vsctl del-br br-tun",
   #}

}
