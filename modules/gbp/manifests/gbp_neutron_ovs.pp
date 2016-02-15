class gbp::gbp_neutron_ovs() {

  $file_exists = inline_template("<% if File.exist?('/etc/neutronplugins/openvswitch/ovs_neutron_plugin.ini') -%>true<% end -%>")

   if $file_exists {
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
   }
}
