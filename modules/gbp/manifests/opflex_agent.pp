class gbp::opflex_agent(
  $opflex_log_level = 'debug2',
  $opflex_peer_ip = '10.0.0.30',
  $opflex_peer_port = '8009',
  $opflex_ssl_mode = 'enabled',
  $opflex_endpoint_dir = '/var/lib/opflex-agent-ovs/endpoints',
  $opflex_ovs_bridge_name = 'br-int',
  $opflex_encap_iface = 'br-int_vxlan0',
  $opflex_uplink_iface = hiera('CONFIG_GBP_OPFLEX_UPLINK_INTERFACE'),
  $opflex_uplink_vlan = '4093',
  $opflex_remote_ip = '10.0.0.32',
  $opflex_remote_port = '8472',
  $opflex_virtual_router = 'true',
  $opflex_router_advertisement = 'false',
  $opflex_virtual_router_mac = '00:22:bd:f8:19:ff',
  $opflex_virtual_dhcp_enabled = 'true',
  $opflex_virtual_dhcp_mac = '00:22:bd:f8:19:ff',
  $opflex_cache_dir = '/var/lib/opflex-agent-ovs/ids',
  $opflex_apic_domain_name = hiera('CONFIG_APIC_DOMAIN_NAME'),
) {

   if !defined(Package['neutron-opflex-agent']) {
      package {'neutron-opflex-agent':
         ensure => installed,
         provider => yum,
      }
   }


   $krel = $::kernelrelease

   if $krel == '3.10.0-229.1.2.el7.x86_64' or $krel == '3.10.0-229.20.1.el7.x86_64' {
      package {'openvswitch-gbp':
         ensure => installed,
         provider => yum,
      }
   } else {
      package {'openvswitch':
         ensure => installed,
         provider => yum,
      }
      package {'openvswitch-gbp-lib':
         ensure => installed,
         provider => yum,
      }
      package {'openvswitch-gbp-devel':
         ensure => installed,
         provider => yum,
      }
   }

   service {'openvswitch':
      ensure => running,
      enable => true,
   }
 
   if $krel == '3.10.0-229.1.2.el7.x86_64' or $krel == '3.10.0-229.20.1.el7.x86_64' {
      package {'agent-ovs':
         ensure => installed,
         provider => yum,
         require => Package['openvswitch-gbp'],
      }
   } else {
      package {'agent-ovs':
         ensure => installed,
         provider => yum,
         require => Package['openvswitch'],
      }
   }

   service {'neutron-openvswitch-agent':
      ensure => stopped,
      enable => 'false',
   }

   service {'neutron-opflex-agent':
      ensure => 'running',
      enable => 'true',
      require => [Package['neutron-opflex-agent'], Service['neutron-openvswitch-agent']],
   }
   
   file {'agent-conf':
     path => '/etc/opflex-agent-ovs/conf.d/opflex-agent-ovs.conf',
     mode => '0644',
     content => template('gbp/opflex-agent-ovs.conf.erb'),
     require => Package['agent-ovs'],
   }

   service {'agent-ovs':
     ensure => running,
     enable => true,
     require => File['agent-conf'],
   }

   exec {'fix_bridge_openflow_version':
      command => "/usr/bin/ovs-vsctl set bridge $opflex_ovs_bridge_name protocols=[]",
   }
   exec {'add_vxlan_port':
      command => "/usr/bin/ovs-vsctl add-port $opflex_ovs_bridge_name $opflex_encap_iface -- set Interface $opflex_encap_iface type=vxlan options:remote_ip=flow options:key=flow options:dst_port=8472",
      onlyif => "/usr/bin/ovs-vsctl show | /bin/grep $opflex_encap_iface | /usr/bin/wc -l",
      returns => [0,1,2],
     require => File['agent-conf'],
   }


#   exec {'offload':
#      command => "/usr/sbin/ethtool --offload $opflex_uplink_iface tx off",
#   }

}
