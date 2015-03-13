class gbp::gbp_neutron_plugin_ovs() {

   neutron_plugin_ovs {
     'ovs/enable_tunneling': value => false;
     'ovs/integration_bridge': value => 'br-int';
   }

   ini_setting { 'try1':
      ensure => absent,
      section => 'ovs',
      path => '/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini',
      setting => 'tunnel_bridge',
   }
   ini_setting { 'try2':
      ensure => absent,
      section => 'ovs',
      path => '/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini',
      setting => 'local_ip',
   }
   ini_setting { 'try3':
      ensure => absent,
      section => 'agent',
      path => '/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini',
      setting => 'vxlan_udp_port',
   }
   ini_setting { 'try4':
      ensure => absent,
      section => 'agent',
      path => '/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini',
      setting => 'tunnel_types',
   }
   exec {'change_nova_shell':
      command => "/usr/sbin/usermod -s /bin/bash nova",
      notify => Service['openstack-nova-compute'],
   }

   service {'openstack-nova-compute':
      ensure => running,
      enable => true,
   }

}
